Meteor.methods
	updateEvents :(obj,operation,relatetodefaultcalendar)->
		if operation==1
			attendees=[]
		else
			events=Events.find({_id:obj._id}).fetch()
			attendees=events[0].attendees	
		if obj._id==obj.parentId
			newattendeesid=_.pluck(obj.attendees,'id');
			oldattendeesid=_.pluck(attendees,'id');
			subattendeesid=_.difference oldattendeesid,newattendeesid;
			addattendeesid=_.difference newattendeesid,oldattendeesid;
			updateattendeesid=_.difference newattendeesid,addattendeesid
			#被去掉的attendees的对应event需要删除
			if relatetodefaultcalendar=='No'
				addattendeesid.push Meteor.userId()
			if relatetodefaultcalendar=='Yes'
				subattendeesid.push Meteor.userId()
			subattendeesid.forEach (attendeeid)->
				calendarid=Calendars.findOne({ownerId:attendeeid},{isDefault:true})._id
				event=Events.find({parentId:obj._id,calendarid:calendarid},{fields:{uri:1}}).fetch()
				Events.direct.remove({parentId:obj._id,calendarid:calendarid})
				Calendar.addChange(calendarid,event[0].uri,3);
			#新加的attendees需要新建event
			doc=Calendar.addCalendarObjects(obj.ownerId,obj,operation);
			addattendeesid.forEach (attendeeid)->
				calendar=Calendars.findOne({ownerId:attendeeid},{isDefault:true}, {fields:{_id: 1,color:1}})
				if calendar==undefined
					Meteor.call('calendarInit',attendeeid,Defaulttimezone);
					calendar=Calendars.findOne({ownerId:attendeeid},{isDefault:true}, {fields:{_id: 1,color:1}})			
				if  doc.calendarid!=calendar._id
					_id = Calendar.uuid()
					Events.direct.insert
						_id:_id;
						title:doc.title
						start:doc.start
						end:doc.end
						allDay:doc.allDay
						calendarid:calendar._id
						description:doc.description
						alarms:doc.alarms
						componenttype:doc.componenttype
						uid:_id
						uri:_id+".ics"
						ownerId:doc.ownerId
						lastmodified:doc.lastmodified
						firstoccurence:doc.firstoccurence
						lastoccurence:doc.lastoccurence
						attendees:doc.attendees
						calendardata:doc.calendardata
						etag:doc.etag
						size:doc.size
						Isdavmodified:false
						parentId:doc.parentId
					Calendar.addChange(calendar._id,_id+".ics",1);
			updateattendeesid.forEach (attendeeid)->
				if attendeeid==obj.ownerId
					Events.direct.update {_id:obj._id}, {$set: 
						calendarid:doc.calendarid}
				Events.direct.update {parentId:obj._id}, {$set: 
					title:doc.title,
					start:doc.start,
					end:doc.end,
					allDay:doc.allDay,
					description:doc.description,
					alarms: doc.alarms,
					remindtimes: doc.remindtimes,
					attendees: doc.attendees,
					componenttype: doc.componenttype,
					lastmodified: doc.lastmodified,
					Isdavmodified:false,
					firstoccurence:doc.firstoccurence,
					lastoccurence: doc.lastoccurence,
					etag: doc.etag,
					size: doc.size,
					calendardata: doc.calendardata,
					parentId:doc.parentId
					},{ multi: true }
				if attendeeid==obj.ownerId
					Calendar.addChange(doc.calendarid,doc.uri,2)
				else
					calendarid=Calendars.findOne({ownerId:attendeeid},{isDefault:true})._id	
					event=Events.find({parentId:obj.parentId,calendarid:calendarid},{fields:{uri:1}})?.fetch()	
					if event		
						Calendar.addChange(calendarid,event[0]?.uri,2)
		else
			Calendar.addCalendarObjects(obj.ownerId,obj,operation);
			Events.direct.update {parentId:obj.parentId}, {$set:
				attendees:obj.attendees},{ multi: true }	
			events=Events.find({parentId:obj.parentId}).fetch()
			events.forEach (event)->
				Calendar.addChange(event.calendarid,event.uri,2)
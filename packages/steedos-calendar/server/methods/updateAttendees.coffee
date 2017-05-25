uuid = require('uuid');
Meteor.methods
	updateAttendees :(obj,operation)->
		if operation==1
			attendees=[]
		else
			events=Events.find({_id:obj._id}).fetch()
			attendees=events[0].attendees
		#attendees=events[0].attendees
		newattendeesid=_.pluck(obj.attendees,'id');
		oldattendeesid=_.pluck(attendees,'id');
		subattendeesid=_.difference oldattendeesid,newattendeesid;
		addattendeesid=_.difference newattendeesid,oldattendeesid;
		updateattendeesid=_.difference newattendeesid,addattendeesid
		#被去掉的attendees的对应event需要删除
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
				_id = uuid()
				Events.direct.insert
					_id:_id;
					title:doc.title
					members:doc.members
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
					eventcolor:calendar.color
					parentId:doc.parentId
				Calendar.addChange(calendar._id,_id+".ics",1);
		#更新所以attendees
		Events.direct.update {parentId:doc.parentId}, {$set: 
			title:doc.title,
			start:doc.start,
			end:doc.end,
			description:doc.description,
			alarms:doc.alarms,
			attendees:doc.attendees,
			componenttype:doc.componenttype
			lastmodified: doc.lastmodified,
			firstoccurence:doc.firstoccurence,
			lastoccurence: doc.lastoccurence,
			etag: doc.etag,
			size: doc.size,
			calendardata: doc.calendardata
		},{ multi: true }
		updateattendeesid.forEach (attendeeid)->
			calendarid=Calendars.findOne({ownerId:attendeeid},{isDefault:true})._id
			event=Events.find({parentId:obj._id,calendarid:calendarid},{fields:{uri:1}}).fetch()
			Calendar.addChange(calendarid,event[0].uri,2)

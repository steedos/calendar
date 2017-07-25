Meteor.methods
	updateEvents :(obj,operation,relatetodefaultcalendar,oldcalendarid)->
		if operation==1
			attendees=[]
		else
			events=Events.find({_id:obj._id}).fetch()
			attendees=events[0].attendees	
		if obj.ownerId==Meteor.userId() || obj.Isdavmodified
			newattendeesid=_.pluck(obj?.attendees,'id');
			if attendees
				oldattendeesid=_.pluck(attendees,'id');
			else
				oldattendeesid=[]
			subattendeesid=_.difference oldattendeesid,newattendeesid;
			addattendeesid=_.difference newattendeesid,oldattendeesid;
			updateattendeesid=_.difference newattendeesid,addattendeesid
			if obj.Isdavmodified
				updateattendeesid.push obj.ownerId
			#被去掉的attendees的对应event需要删除
			if relatetodefaultcalendar=='No'
				addattendeesid.push Meteor.userId()
			if relatetodefaultcalendar=='Yes'
				subattendeesid.push Meteor.userId()
				Calendar.addChange(oldcalendarid,obj.uri,3);
				#if obj.Isdavmodified==true

			subattendeesid.forEach (attendeeid)->
				calendarid=Calendars.findOne({ownerId:attendeeid},{isDefault:true})._id
				event=Events.find({parentId:obj._id,calendarid:calendarid},{fields:{uri:1}}).fetch()
				if attendeeid != obj.ownerId
					Events.direct.remove({parentId:obj._id,calendarid:calendarid})
				Calendar.addChange(calendarid,event[0]?.uri,3);

				payload = 
					app: 'calendar'
					id: attendeeid
				start = moment(obj.start).format("YYYY-MM-DD HH:mm")
				site = obj.site || ""
				title = "您的会议邀请已取消"
				text = "会议时间:#{start}\r会议地点:#{site}"
				Push.send
					createdAt: new Date()
					createdBy: '<SERVER>'
					from: 'calendar',
					title: title,
					text: text,
					payload: payload
					badge: 12,
					query: {userId:attendeeid,appName:"calendar"}

			#新加的attendees需要新建event
			doc=Calendar.addCalendarObjects(obj.ownerId,obj,operation);	
			addattendeesid.forEach (attendeeid)->
				calendar=Calendars.findOne({ownerId:attendeeid},{isDefault:true}, {fields:{_id: 1,color:1}})				
				if calendar==undefined
					Meteor.call('calendarInit',attendeeid,Defaulttimezone);
					calendar=Calendars.findOne({ownerId:attendeeid},{isDefault:true}, {fields:{_id: 1,color:1}})			
				if  doc.calendarid!=calendar?._id
					_id = Calendar.uuid()
					Events.direct.insert
						_id:_id;
						title:doc.title
						start:doc.start
						end:doc.end
						allDay:doc.allDay
						calendarid:calendar._id
						site:doc.site
						participation:doc.participation
						description:doc.description
						alarms:doc.alarms
						remindtimes: doc.remindtimes
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

				payload = 
					app: 'calendar'
					id: attendeeid
				start = moment(doc.start).format("YYYY-MM-DD HH:mm")
				site = doc.site || ""
				title = "您有新的会议邀请"
				text = "会议时间:#{start}\r会议地点:#{site}"
				Push.send
					createdAt: new Date()
					createdBy: '<SERVER>'
					from: 'calendar',
					title: title,
					text: text,
					payload: payload
					badge: 12,
					query: {userId:attendeeid,appName:"calendar"}

			updateattendeesid.forEach (attendeeid)->
				if attendeeid==obj.ownerId and obj._id==obj.parentId
					Events.direct.update {_id:obj._id}, {$set: 
						calendarid:doc.calendarid}
					Calendar.addChange(doc.calendarid,doc.uri,2)

				payload = 
					app: 'calendar'
					id: attendeeid
				start = moment(doc.start).format("YYYY-MM-DD HH:mm")
				site = doc.site || ""
				title = "您的会议信息有修改"
				text = "会议时间:#{start}\r会议地点:#{site}"
				Push.send
					createdAt: new Date()
					createdBy: '<SERVER>'
					from: 'calendar',
					title: title,
					text: text,
					payload: payload
					badge: 12,
					query: {userId:attendeeid,appName:"calendar"}

			Events.direct.update {parentId:obj.parentId}, {$set: 
				title:doc.title,
				start:doc.start,
				end:doc.end,
				allDay:doc.allDay,
				site:doc.site,
				participation:doc.participation,
				description:doc.description,
				alarms: doc.alarms,
				remindtimes: doc.remindtimes,
				attendees: doc.attendees,
				ownerId:doc.ownerId
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
			events=Events.find({parentId:obj._id}).fetch()
			events.forEach (event)->
				Calendar.addChange(event.calendarid,event.uri,2)
		else
			Calendar.addCalendarObjects(obj.ownerId,obj,operation);
			Events.direct.update {parentId:obj.parentId}, {$set:
				attendees:obj?.attendees},{ multi: true }
			Events.direct.update {_id:obj._id}, {$set:
				alarms:obj.alarms
				remindtimes:obj.remindtimes}	
			events=Events.find({parentId:obj.parentId}).fetch()
			events.forEach (event)->
				Calendar.addChange(event.calendarid,event.uri,2)
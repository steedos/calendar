import { Calendar } from '../main';
import moment from 'moment'
Meteor.methods
	updateEvents :(obj,operation,relatetodefaultcalendar,oldcalendarid)->
		if operation==1
			attendees=[]
		else
			events=Events.find({_id:obj._id}).fetch()
			attendees=events[0].attendees	
		if obj._id==obj.parentId || obj.Isdavmodified			
			currenttime = new Date()
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
			if relatetodefaultcalendar=='No' and updateattendeesid.indexOf(obj.ownerId)>-1
				addattendeesid.push Meteor.userId()
			if relatetodefaultcalendar=='Yes'and updateattendeesid.indexOf(obj.ownerId)>-1
				subattendeesid.push Meteor.userId()
				#Calendar.addChange(oldcalendarid,obj.uri,3);
			subattendeesid.forEach (attendeeid)->				
				calendarid=Calendars.findOne({ownerId:attendeeid,isDefault:true})._id
				event=Events.find({parentId:obj._id,calendarid:calendarid},{fields:{uri:1}}).fetch()
				Events.direct.remove({parentId:obj._id,calendarid:calendarid})
				Calendar.addChange(calendarid,event[0]?.uri,3);
				if events[0].attendees[oldattendeesid.indexOf(attendeeid)].partstat=='ACCEPTED' and obj.end - currenttime>0
					Meteor.call('eventNotification',obj,attendeeid,3)
			#新加的attendees需要新建event
			doc=Calendar.addCalendarObjects(obj.ownerId,obj,operation);	
			addattendeesid.forEach (attendeeid)->
				calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})				
				if calendar==undefined
					Meteor.call('calendarInit',attendeeid,Defaulttimezone);
					calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})			
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
						componenttype:"VEVENT"
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
				if currenttime- doc.end<0
					Meteor.call('eventNotification',doc,attendeeid,1)
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
				componenttype:"VEVENT",
				lastmodified: doc.lastmodified,
				Isdavmodified:false,
				firstoccurence:doc.firstoccurence,
				lastoccurence: doc.lastoccurence,
				etag: doc.etag,
				size: doc.size,
				calendardata:doc.calendardata,
				parentId:doc.parentId
				},{ multi: true }
			Events.direct.update {_id:obj._id}, {$set: 
						calendarid:doc.calendarid}
			Calendar.addChange(doc.calendarid,doc.uid+".ics",2)
			updateattendeesid.forEach (attendeeid)->
				if obj._id==obj.parentId
					Events.direct.update {_id:obj._id}, {$set: 
						calendarid:doc.calendarid}
					Calendar.addChange(doc.calendarid,doc.uid+".ics",2)
				calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})
				event = Events.findOne({calendarid:calendar._id,parentId:doc.parentId})
				Calendar.addChange(event.calendarid,event.uri+".ics",2);
				if currenttime- doc.end<0
					Meteor.call('eventNotification',doc,attendeeid,2)
			# events=Events.find({parentId:obj.parentId}).fetch()
			# events.forEach (event)->
			# 	isDefaultCalendar=Calendars.findOne({_id:event.calendarid}).isDefault
			# 	if isDefaultCalendar
			# 		Calendar.addChange(event.calendarid,event.uri,2)
		else
			Calendar.addCalendarObjects(obj.ownerId,obj,operation);
			Events.direct.update {parentId:obj.parentId}, {$set:
				attendees:obj?.attendees},{ multi: true }
			Events.direct.update {_id:obj._id}, {$set:
				alarms:obj.alarms
				remindtimes:obj.remindtimes}	
			events=Events.find({parentId:obj.parentId}).fetch()
			events.forEach (event)->
				isDefaultCalendar=Calendars.findOne({_id:event.calendarid}).isDefault
				if isDefaultCalendar
					Calendar.addChange(event.calendarid,event.uri,2)
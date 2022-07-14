import { Calendar } from '../main';
import moment from 'moment'
Meteor.methods
	eventInit: (userId,doc) ->
		doc.componenttype = "VEVENT"
		doc._id = Calendar.uuid()
		doc.uid = doc._id	
		doc.uri = doc._id + ".ics"
		doc.Isdavmodified = false
		doc = Calendar.addCalendarObjects(userId,doc,1)
		isDefaultCalendar=Calendars.findOne({_id:doc.calendarid}).isDefault
		if isDefaultCalendar
			addMembers=[]
			addMembers.push userId
			doc = Meteor.call('attendeesInit',doc,addMembers)
		Events.insert(doc,(error,result)->
				if !error
					return result
				else
					console.log error
					return
			)
		attendeesid=_.pluck(doc.attendees,'id')
		dx=attendeesid.indexOf(userId)
		# isDefaultCalendar=Calendars.findOne({ownerId:userId},{_id:doc.calendarid}).isDefault
		# if !isDefaultCalendar and dx<0 and attendeesid.length==0
		#  	attendeesid.push(userId)
		attendeesid.forEach (attendeeid)->
				calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})				
				if calendar==undefined
					Meteor.call('calendarInit',attendeeid,Defaulttimezone);
					calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})			
				if  doc.calendarid!=calendar?._id
					_id = Calendar.uuid()
		#calendar=Calendars.findOne({ownerId:userId},{isDefault:true}, {fields:{_id: 1,color:1}})
		#if calendar._id !=doc.calendarid
			#_id = Calendar.uuid()
					obj = {
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
						componenttype:doc.componenttype
						uid:_id
						uri:_id+".ics"
						ownerId:doc.ownerId
						lastmodified:doc.lastmodified
						Isdavmodified:false
						firstoccurence:doc.firstoccurence
						lastoccurence:doc.lastoccurence
						attendees:doc.attendees
						calendardata:doc.calendardata
						etag:doc.etag
						size:doc.size
						eventcolor:calendar.color
						parentId:doc.parentId
						space:doc.space
					}
					Events.direct.insert obj
					Calendar.addChange(calendar._id,_id+".ics",1);
				else
					Calendar.addChange(doc.calendarid,doc.uri,1);
				currenttime = new Date()
				if currenttime- doc.end<0
					Meteor.call('eventNotification',doc,attendeeid,1)
		Calendar.addChange(doc.calendarid,doc.uri,1);
		return doc
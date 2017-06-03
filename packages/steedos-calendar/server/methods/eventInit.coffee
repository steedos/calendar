Meteor.methods
	eventInit: (userId,doc) ->
		doc.componenttype = "VEVENT"
		doc._id = Calendar.uuid()
		doc.uid = doc._id	
		doc.uri = doc._id + ".ics"
		doc.ownerId=userId
		attendees=[]
		attendee = {
			role:"REQ-PARTICIPANT",
			cutype:"INDIVIDUAL",
			partstat:"ACCEPTED",
			cn:Meteor.users.findOne({_id:userId}).name,
			mailto:Meteor.users.findOne({_id:userId}).steedos_id,
			id:userId,
			description:null
		}
		attendees.push attendee  	
		doc?.attendees = attendees
		doc = Calendar.addCalendarObjects(userId,doc,1)
		Events.insert(doc,(error,result)->
				if !error
					console.log result
					return result
				else
					console.log error
					return
			)
		calendar=Calendars.findOne({ownerId:userId},{isDefault:true}, {fields:{_id: 1,color:1}})
		if calendar._id !=doc.calendarid
			_id = Calendar.uuid()
			Events.direct.insert
				_id:_id;
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
		else
			Calendar.addChange(doc.calendarid,doc.uri,1);

		return doc
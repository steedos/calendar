Meteor.methods
	eventInit: (userId,doc) ->
		doc.componenttype = "VEVENT"
		doc._id = Calendar.uuid()
		doc.uid = doc._id	
		doc.uri = doc._id + ".ics"
		doc.Isdavmodified = false
		doc = Calendar.addCalendarObjects(userId,doc,1)
		Events.insert(doc,(error,result)->
				if !error
					return result
				else
					console.log error
					return
			)
		attendeesid=_.pluck(doc.attendees,'id')
		attendeesid.forEach (attendeeid)->
				calendar=Calendars.findOne({ownerId:attendeeid},{isDefault:true}, {fields:{_id: 1,color:1}})				
				if calendar==undefined
					Meteor.call('calendarInit',attendeeid,Defaulttimezone);
					calendar=Calendars.findOne({ownerId:attendeeid},{isDefault:true}, {fields:{_id: 1,color:1}})			
				if  doc.calendarid!=calendar?._id
					_id = Calendar.uuid()
		#calendar=Calendars.findOne({ownerId:userId},{isDefault:true}, {fields:{_id: 1,color:1}})
		#if calendar._id !=doc.calendarid
			#_id = Calendar.uuid()
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
						Isdavmodified:false
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
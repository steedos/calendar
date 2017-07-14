Meteor.methods
	updateSubcalendar:(calendarObj)->
		subCalendars = calendarsubscriptions.find({uri:calendarObj._id})?.fetch()
		if subCalendars.length > 0
			subCalendars.forEach (subCalendarObj,index) -> 
				calendarsubscriptions.update({_id:subCalendarObj._id},{$set:{calendarname:calendarObj.title}})
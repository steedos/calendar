Meteor.methods
	removeSubCalendars:(calendarId) ->
		if calendarId
			calendarsubscriptions.remove({uri:calendarId})
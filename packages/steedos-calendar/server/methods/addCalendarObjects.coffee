Meteor.methods
	addCalendarObjects: (userId, doc,operation) ->
		Calendar.addCalendarObjects(userId,doc,operation)
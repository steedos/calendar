import { Calendar } from '../main';
Meteor.methods
	addCalendarObjects: (userId, doc,operation) ->
		Calendar.addCalendarObjects(userId,doc,operation)
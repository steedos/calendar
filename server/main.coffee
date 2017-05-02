import { Meteor } from 'meteor/meteor';

Meteor.startup ->
	
@Calendar = 
	addChange : (calendarId, objectUri, operation)->
		oldsynctoken = Calendars.findOne({_id:calendarId}).synctoken?1;
		calendarchanges.insert
			uri:objectUri,
			syntoken: oldsynctoken,
			calendarid: calendarId,
			operation: operation
		Calendars.update({_id:calendarId},{$set:{synctoken:oldsynctoken+1}});
		
@calendarsubscriptions = new Mongo.Collection('calendar_subscriptions');

calendarsubscriptions.attachSchema new SimpleSchema 
	_id:  
		type: String
		optional: true
		autoform: 
			omit: true

	uri:  
		type: String
		optional: true
	
	principaluri:  
		type: String
		optional: true

	calendarcolor:
		type: String
			
if (Meteor.isServer) 
	calendarsubscriptions.allow 
		insert: (userId, doc) ->
			return true

		update: (userId, doc) ->
			return true

		remove: (userId, doc) ->
			return true


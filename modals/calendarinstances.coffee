@calendarinstances = new Mongo.Collection('calendar_instances');
icalendar = require('icalendar');

calendarinstances.attachSchema new SimpleSchema 
	_id:  
		type: String
		optional: true
		autoform: 
			omit: true

	principaluri:  
		type: String
		optional: true
		autoform: 
			omit: true

	uri:  
		type: String
		optional: true
		autoform: 
			omit: true
	
	transparent:  
		type: Number
		optional: true
		autoform: 
			omit: true

	access:  
		type: Number,
		optional: true
		optional: true
		autoform: 
			omit: true

	share_invitestatus: 
		type: Number,
		optional: true
		autoform: 
			omit: true

	calendarid:
		type: String,
		optional: true
		autoform: 
			omit: true
				
	displayname:  
		type: String,
		optional: true
		autoform: 
			omit: true

	description:  
		type: String,
		optional: true
		autoform: 
			omit: true

	timezone:
		type: String,
		optional: true
		autoform: 
			omit: true

	calendarorder:
		type: String,
		optional: true
		autoform: 
			omit: true

	calendarcolor:
		type: Number,
		optional: true
		autoform: 
			omit: true

if (Meteor.isServer) 
	calendarinstances.allow 
		calendarinstances.insert: (userId, doc) ->
			principaluri:"principals/" + userId,
			uri:doc.ownerId,
			transparent:1,
			access:1,
			share_invitestatus:2,
			calendarid:doc_id,
			displayname:doc.title,
			description:"null",
			timezone:"Asia/Shanghai",
			calendarorder:'',
			calendarcolor:doc.color
			return true

		update: (userId, doc) ->
			return true

		remove: (userId, doc) ->
			return true

		
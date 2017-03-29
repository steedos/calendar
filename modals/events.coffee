@Events = new Mongo.Collection('calendar_events');

Events.attachSchema new SimpleSchema 
	start:  
		type: Date
		autoform: 
			type: "bootstrap-datetimepicker"

	end:  
		type: Date,
		optional: true
		autoform: 
			type: "bootstrap-datetimepicker"

	allDay: 
		type: Boolean,
		defaultValue: true,
		optional: true

	title:  
		type: String

	description:  
		type: String,
		optional: true

	ownerId:  
		type: String,
		optional: true
		autoform: 
			omit: true



if (Meteor.isServer) 
	Events.allow 
		insert: (userId, doc) ->
			return true

		update: (userId, doc) ->
			return true

		remove: (userId, doc) ->
			return true

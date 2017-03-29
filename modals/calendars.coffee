@Calendars = new Mongo.Collection('calendars');

Calendars.attachSchema new SimpleSchema 
	title:  
		type: String
	color:  
		type: String
	members:  
		type: [String],
		optional: true
		autoform: 
			omit: true

	ownerId:  
		type: String,
		optional: true
		autoform: 
			omit: true


if (Meteor.isServer) 
	Calendars.allow 
		insert: (userId, event) ->
			return true

		update: (userId, event) ->
			return true

		remove: (userId, event) ->
			return true


#删除后的操作
@calendarsubscriptions = new Mongo.Collection('calendar_subscriptions');

calendarsubscriptions._simpleSchema = new SimpleSchema 
	_id:  
		type: String
		optional: true
		autoform: 
			omit: true

	uri:  
		type: String
		optional: true
		autoform: 
			omit: true
	
	principaluri:  
		type: String
		optional: true
		autoform: 
			omit: true

	calendarname:
		type: String
		autoform: 
			disabled: true

	color:
		type: String
		autoform:
			type: "bootstrap-minicolors"

calendarsubscriptions.attachSchema calendarsubscriptions._simpleSchema

if Meteor.isClient
	calendarsubscriptions._simpleSchema.i18n("calendar_subscriptions");

			
if (Meteor.isServer) 
	calendarsubscriptions.allow 
		insert: (userId, doc) ->
			return true

		update: (userId, doc) ->
			return true

		remove: (userId, doc) ->
			return true
if Meteor.isServer
	calendarsubscriptions._ensureIndex({
			"uri":1,
			"principaluri": 1
		},{background: true})
	calendarsubscriptions._ensureIndex({
			"uri":1
		},{background: true})
	calendarsubscriptions._ensureIndex({
			"_id":1
		})
	calendarsubscriptions._ensureIndex({
			"principaluri":1
		},{background: true})
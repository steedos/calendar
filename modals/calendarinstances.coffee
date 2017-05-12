@calendarinstances = new Mongo.Collection('calendar_instances');
icalendar = require('icalendar');
calendarinstances.attachSchema new SimpleSchema 

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
		type: Boolean
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
		type: String,
		optional: true
		autoform: 
			omit: true

	share_herf:
		type: String,
		optional: true
		autoform: 
			omit: true

	share_displayname:
		type: String,
		optional: true
		autoform: 
			omit: true

if (Meteor.isServer) 
	calendarinstances.allow 
		insert: (userId, doc) ->
			return true

		update: (userId, doc) ->
			return true

		remove: (userId, doc) ->
			return true

	calendarinstances.before.insert (userId,doc)->
		ical = new icalendar.iCalendar();
		vevent = new icalendar.VEvent(doc._id);
		vtimezone=ical.addComponent('VTIMEZONE');
		vtimezone.addProperty("TZID","Asia/Shanghai");
		standard = vtimezone.addComponent("STANDARD");
		standard.addProperty("TZOFFSETFROM","0800");
		standard.addProperty("TZOFFSETTO","0800");
		standard.addProperty("TZNAME","CST");
		daylight = vtimezone.addComponent("DAYLIGHT");
		daylight.addProperty("TZOFFSETFROM","0800");
		daylight.addProperty("TZNAME","GMT+8");
		daylight.addProperty("TZOFFSETTO","0900");
		timezone = ical.toString();
		doc.timezone = timezone;

    
		
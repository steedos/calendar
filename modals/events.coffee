@Events = new Mongo.Collection('calendar_objects');
uuid = require('uuid');
MD5 = require('MD5');
icalendar = require('icalendar');
Events.attachSchema new SimpleSchema 
	title:  
		type: String

	members:  
		type: [String],
		autoform: 
			type: "universe-select"
			afFieldInput:
				multiple: true
				optionsMethod: "selectGetUsers"

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

	calendarid:
		type: String,
		autoform:
			type: "select"
			options: ()->
				options = []
				objs = Calendars.find({})
				objs.forEach (obj) ->
					options.push
						label: t(obj.title),
						value: obj._id
				# options[1].select='select'
				return options
				
	description:  
		type: String,
		optional: true,
		autoform:
			rows:2

	ownerId:  
		type: String,
		optional: true
		autoform: 
			omit: true

	alarms:
		type: [String],
		optional: true
		autoform: 
			type: "select-multiple"
			options: [
				{label: "事件发生时", value: "-PT0S"},
				{label: "5 分钟前", value: "-PT5M"},
				{label: "10 分钟前", value: "-PT10M"},
				{label: "15 分钟前", value: "-PT15M"},
				{label: "30 分钟前", value: "-PT30M"},
				{label: "1 小时前", value: "-PT1H"},
				{label: "2 小时前", value: "-PT2H"},
				{label: "1 天前", value: "-P1D"},
				{label: "2 天前", value: "-P2D"}
			]
	componenttype:
		type: String,
		optional: true
		autoform: 
			omit: true

	etag:
		type: String,
		optional: true
		autoform: 
			omit: true

	firstoccurence:
		type: Number,
		optional: true
		autoform: 
			omit: true

	lastmodified:
		type: Number,
		optional: true
		autoform: 
			omit: true

	lastoccurence:
		type: Number,
		optional: true
		autoform: 
			omit: true

	size:
		type: Number,
		optional: true
		autoform: 
			omit: true

	uid:
		type: String,
		optional: true
		autoform: 
			omit: true

	uri:
		type: String,
		optional: true
		autoform: 
			omit: true

	calendardata:
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

	Events.before.insert (userId, doc)->
		doc.componenttype = "VEVENT"
		doc._id = uuid()
		doc.uri = doc._id + ".ics"
		ical = new icalendar.iCalendar();
		vevent = new icalendar.VEvent(doc._id);
		#valarm = new vevent.VAlarm();
		#Vtimezone = new iCalendar.VTimezone()；
		ical.addComponent(vevent);
		alarm = vevent.addComponent('VALARM');
		alarm.addProperty('ACTION', 'DISPLAY');
		alarm.addProperty('TRIGGER;VALUE = DURATION', doc.alarms);
		vevent.setDescription(doc.description);
		vevent.addProperty("TRANSP","OPAQUE");#得改
		#crated 创建的时间，暂时这样写，得改
		vevent.addProperty("CREATED",new Date());
		vevent.addProperty("LAST-MODIFIED",new Date());
		vevent.setSummary(doc.title);
		vevent.addProperty("ORGANIZER",Meteor.users.findOne({_id:userId}).steedos_id);
		vevent.setLocation("Shanghai");
		for member,i in doc.members 
			member = doc.members[i]
			vevent.addProperty("ATTENDEE;RSVP=TRUE;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;SCHEDULE-STATUS=3.7", Meteor.users.findOne({_id:member}).steedos_id);
		if doc.allDay==true
			vevent.addProperty("DTSTART;VALUE=DATE",moment(new Date(doc.start)).format("YYYYMMDD"));
			vevent.addProperty("DTEND;VALUE=DATE",moment(new Date(doc.end)).format("YYYYMMDD"));
		else
			vevent.addProperty("DTSTART;TZID=Asia/Shanghai",moment(new Date(doc.start)).format("YYYYMMDDThhmmss"));#TZID得改
			vevent.addProperty("DTEND;TZID=Asia/Shanghai",moment(new Date(doc.end)).format("YYYYMMDDThhmmss"));
		vevent.addProperty("SEQUENCE",3);#得改
		#doc.calendarid = doc._id;
		myDate = new Date();
		doc.lastmodified = parseInt(myDate.getTime());
		myDate = new Date(doc.start)
		doc.firstoccurence = parseInt(myDate.getTime());
		myDate = new Date (doc.end)
		doc.lastoccurence = parseInt(myDate.getTime());
		doc.calendardata = ical.toString();
		doc.etag = MD5(doc.calendardata);
		doc.size = doc.calendardata.length;
		doc.uid = doc._id
		return
	
	Events.after.insert (userId, doc)->
		starttoken = Calendars.findOne({_id:doc.calendarid}).synctoken;
		Calendar.addChange(doc.calendarid,starttoken,10,doc.uri,1);
		return

	Events.before.update (userId, doc, fieldNames, modifier, options) ->
		modifier.$set = modifier.$set || {};
		return
		
	Events.after.update (userId, doc, fieldNames, modifier, options) ->
		myDate = new Date();
		lastmodified = parseInt(myDate.getTime());
		myDate = new Date(doc.start);
		firstoccurence = parseInt(myDate.getTime());
		myDate = new Date (doc.end);
		lastoccurence = parseInt(myDate.getTime());
		# oldcalendardata = Events.findOne({_id:doc._id}).calendardata;
		# console.log oldcalendardata;
		# ical = icalendar.parse_calendar(oldcalendardata);
		ical = new icalendar.iCalendar();
		vevent = new icalendar.VEvent(doc._id);
		ical.addComponent(vevent);
		vevent.setProperty("LAST-MODIFIED",new Date());
		vevent.setDescription(doc.description);	
		vevent.setSummary(doc.title);
		for member,i in doc.members 
			member = doc.members[i]
			vevent.setProperty("ATTENDEE;RSVP=TRUE;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;SCHEDULE-STATUS=3.7", Meteor.users.findOne({_id:member}).steedos_id);
		if doc.allDay==true
			vevent.setProperty("DTSTART;VALUE=DATE",moment(new Date(doc.start)).format("YYYYMMDD"));
			vevent.setProperty("DTEND;VALUE=DATE",moment(new Date(doc.end)).format("YYYYMMDD"));
		else
			vevent.setProperty("DTSTART;TZID=Asia/Shanghai",moment(new Date(doc.start)).format("YYYYMMDDThhmmss"));#TZID得改
			vevent.setProperty("DTEND;TZID=Asia/Shanghai",moment(new Date(doc.end)).format("YYYYMMDDThhmmss"));
		newcalendardata = ical.toString();
		size = newcalendardata.length
		Events.direct.update {_id:doc._id}, $set:
			lastmodified: lastmodified,
			firstoccurence:firstoccurence,
			lastoccurence: lastoccurence,
			etag: MD5(newcalendardata),
			size: size,
			calendardata: newcalendardata

		starttoken = Calendars.findOne({_id:doc.calendarid}).synctoken;
		Calendar.addChange(doc.calendarid,starttoken,10,doc.uri,2)
		return
	
	
	#删除后的操作，同时删除关联的event事件  after delete
	Events.before.remove (userId, doc)->
		return

	Events.after.remove (userId, doc)->
		starttoken = Calendars.findOne({_id:doc.calendarid}).synctoken;
		Calendar.addChange(doc.calendarid,starttoken,1,doc.uri,3)
		return

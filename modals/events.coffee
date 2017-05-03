@Events = new Mongo.Collection('calendar_objects');
uuid = require('uuid');
MD5 = require('MD5');
jstz = require('jstz');
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

timezone = jstz.determine();
if (Meteor.isServer) 
	Events.allow 
		insert: (userId, doc) ->
			return true

		update: (userId, doc) ->
			return true

		remove: (userId, doc) ->
			return true
	Events.before.insert (userId, doc)->
		console.log doc
		doc.componenttype = "VEVENT"
		doc._id = uuid()
		doc.uri = doc._id + ".ics"
		ical = new icalendar.iCalendar();
		vevent = new icalendar.VEvent(doc._id);
		#Vtimezone = new iCalendar.VTimezone()；
		ical.addComponent(vevent);
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
		doc.calendardata = vevent.toString();
		doc.etag = MD5(doc.calendardata);
		doc.size = doc.calendardata.length
		doc.uid = doc._id
	
	Events.after.insert (userId, doc)->
			Calendar.addChange(doc.calendarid,doc._id,1);

	Events.before.update (userId, doc, fieldNames, modifier, options) ->
		modifier.$set = modifier.$set || {};
		
	Events.after.update (userId, doc, fieldNames, modifier, options) ->
		myDate = new Date();
		lastmodified = parseInt(myDate.getTime());
		myDate = new Date(doc.start);
		firstoccurence = parseInt(myDate.getTime());
		myDate = new Date (doc.end);
		lastoccurence = parseInt(myDate.getTime());
		oldcalendardata = Events.findOne({_id:doc._id}).calendardata;
		console.log oldcalendardata;
		ical = icalendar.parse_calendar(oldcalendardata);
		console.log ical
		vevent = ical.events();
		vevent[0].setProperty("LAST-MODIFIED",new Date());
		vevent[0].setDescription(doc.description);	
		vevent[0].setSummary(doc.title);
		for member,i in doc.members 
			member = doc.members[i]
			vevent[0].setProperty("ATTENDEE;RSVP=TRUE;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;SCHEDULE-STATUS=3.7", Meteor.users.findOne({_id:member}).steedos_id);
		if doc.allDay==true
			vevent[0].setProperty("DTSTART;VALUE=DATE",moment(new Date(doc.start)).format("YYYYMMDD"));
			vevent[0].setProperty("DTEND;VALUE=DATE",moment(new Date(doc.end)).format("YYYYMMDD"));
		else
			vevent[0].setProperty("DTSTART;TZID=Asia/Shanghai",moment(new Date(doc.start)).format("YYYYMMDDThhmmss"));#TZID得改
			vevent[0].setProperty("DTEND;TZID=Asia/Shanghai",moment(new Date(doc.end)).format("YYYYMMDDThhmmss"));
		newcalendardata = vevent[0].toString();
		size = newcalendardata.length
		Events.direct.update({_id:_id},{$set:{
			_id:doc._id,
			title:doc.title,
			members:members,
			start:doc.start,
			end: doc.end,
			allDay:doc.allDay,
			calendarid:doc.calendarid,
			description:doc.description,
			lastmodified: lastmodified,
			firstoccurence:firstoccurence,
			lastoccurence: lastoccurence,
			etag: MD5(newcalendardata),
			size: size
			}})	

		Calendar.addChange(doc.calendarid,doc._id,2);
	
	
	#删除后的操作，同时删除关联的event事件  after delete
	Events.before.remove (userId, doc)->
	Events.after.remove (userId, doc)->
		Calendar.addChange(doc.calendarid,doc._id,3);



	
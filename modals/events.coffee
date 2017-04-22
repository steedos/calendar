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


	Events.before.update (userId, doc, fieldNames, modifier, options)->


	Events.before.insert (userId, doc)->
		console.log doc
		doc.componenttype = "VEVENT"
		doc._id = uuid()
		doc.uri = doc._id + ".ics"
		vevent = new icalendar.VEvent(doc._id);
		vevent.addProperty("DESCRIPTION",doc.description);
		vevent.addProperty("TRANSP","OPAQUE");#得改
		#crated 创建的时间，暂时这样写，得改
		vevent.addProperty("CREATED",new Date());
		vevent.addProperty("LAST-MODIFIED",new Date());
		vevent.setSummary(doc.title);
		vevent.addProperty("ORGANIZER",Meteor.users.findOne({_id:userId}).steedos_id);
		vevent.addProperty("LOCATION","Shanghai")
		for member,i in doc.members 
			member = doc.members[i]
			vevent.addProperty("ATTENDEE;RSVP=TRUE;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;SCHEDULE-STATUS=3.7", Meteor.users.findOne({_id:member}).steedos_id);
		if doc.allDay==true
			vevent.addProperty("DTSTART;VALUE=DATE",new Date(doc.start).Format("yyyymmdd"));#TZID得改
			vevent.addProperty("DTEND;VALUE=DATE",doc.end.getDate());
		else
			vevent.addProperty("DTSTART;TZID=Asia/Shanghai",doc.start);#TZID得改
			vevent.addProperty("DTEND;TZID=Asia/Shanghai",doc.end);
		vevent.addProperty("SEQUENCE",3);#得改
		#doc.calendarid = doc.obj._id;
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
	#删除后的操作，同时删除关联的event事件  after delete
	Events.before.remove (userId, doc)->


	Events.before.update (userId, doc, fieldNames, modifier, options) ->
		console.log "doc:#{doc}"
		modifier.$set = modifier.$set || {};


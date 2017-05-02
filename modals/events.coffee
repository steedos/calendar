@Events = new Mongo.Collection('calendar_objects');
uuid = require('uuid');
MD5 = require('MD5');
jstz = require('jstz');
icalendar = require('icalendar');
sync=1
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
		#doc._id = uuid()
		doc.uri = doc._id + ".ics"
		vevent = new icalendar.VEvent(doc._id);
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
		if sync==1
			Calendar.addChange(doc.calendarid,doc._id,1);

	Events.before.update (userId, doc, fieldNames, modifier, options) ->
		modifier.$set = modifier.$set || {};
		
	Events.after.update (userId, doc, fieldNames, modifier, options) ->
		title = doc.title
		members = doc.members
		start = doc.start
		end =doc.end
		allDay = doc.allDay
		calendarid = doc.calendarid
		description = doc.description
		ownerId = doc.ownerId
		_id = doc._id
		sync=0
		Events.remove({"_id":_id})
		Events.insert
			_id:_id,
			title:title,
			members:members,
			start:start,
			end: end,
			allDay:allDay,
			calendarid:calendarid,
			description:description
		Calendar.addChange(doc.calendarid,doc._id,2);
	
	#删除后的操作，同时删除关联的event事件  after delete
	Events.before.remove (userId, doc)->
	Events.after.remove (userId, doc)->
		if sync==1	
			Calendar.addChange(doc.calendarid,doc._id,3);



	
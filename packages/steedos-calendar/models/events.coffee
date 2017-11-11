@Events = new Mongo.Collection('calendar_objects');
moment_timezone = require('moment-timezone');
# icalendar = require('icalendar');
created = new Date();
# locale = Session.get 'steedos-locale'

Events._simpleSchema = new SimpleSchema
	title:
		type: String
		max: 50
		optional: true
		autoform:
			type:"text"
			defaultValue:()->
				return t("new_event")

	allDay:
		type: Boolean
		# label:t("calendar_event_allDay")
		defaultValue: false
		optional: true

	afternoon:
		type: String,
		optional: true
		autoform:
			type: 'button'
			value: ()->
				return t("calendar_afternoon")

	morning:
		type: String,
		optional: true
		autoform:
			type: 'button'
			value: ()->
				return t("calendar_morning")

	start:
		type: Date
		autoform: 
			type:()->
				if Steedos.isMobile() or Steedos.isAndroidOrIOS()
					return "datetime-local"
				else
					return "bootstrap-datetimepicker"
			dateTimePickerOptions:()->
				if Steedos.isMobile() or Steedos.isAndroidOrIOS()
					return null
				else
					return  {
						locale: Session.get("TAPi18n::loaded_lang")
						format:"YYYY-MM-DD HH:mm"
						sideBySide:true
					}

	end:
		type: Date
		autoform: 
			type:()->
				if Steedos.isMobile() or Steedos.isAndroidOrIOS()
					return "datetime-local"
				else
					return "bootstrap-datetimepicker"
			dateTimePickerOptions:()->
				if Steedos.isMobile() or Steedos.isAndroidOrIOS()
					return null
				else
					return  {
						locale: Session.get("TAPi18n::loaded_lang")
						format:"YYYY-MM-DD HH:mm"
						sideBySide:true
					}
			defaultValue:()->
				return Session.get "endTime"

	alarms:
		type: [String]
		# label:t("calendar_event_alarms")
		optional: true
		autoform: 
			type: "universe-select"
			multiple: true
			options: () ->
				if Session?.get("isAllDay")
					options=[
						# {label: t("events_alarms_label_immediately"),value:"Now"},
						{label: t("events_alarms_label_1_day_before"), value: "-PT15H"},
						{label: t("events_alarms_label_2_days_before"), value: "-P1DT15H"},
						{label: t("events_alarms_label_1_week_before"), value: "-P6DT15H"}
					]
				else
					options=[
						# {label: t("events_alarms_label_immediately"),value:"Now"},
						{label: t("events_alarms_label_when_events_occur"), value: "-PT0S"},
						{label: t("events_alarms_label_5_minutes_before"), value: "-PT5M"},
						{label: t("events_alarms_label_10_minutes_before"), value: "-PT10M"},
						{label: t("events_alarms_label_15_minutes_before"), value: "-PT15M"},
						{label: t("events_alarms_label_30_minutes_before"), value: "-PT30M"},
						{label: t("events_alarms_label_1_hour_before"), value: "-PT1H"},
						{label: t("events_alarms_label_2_hours_before"), value: "-PT2H"},
						{label: t("events_alarms_label_24_hours_before"), value: "-P1D"},
						{label: t("events_alarms_label_48_hours_before"), value: "-P2D"}
					]
				return options			
			defaultValue:()->
				if !Session?.get("isAllDay")
					return "-PT15M"
			sortMethod:"x"
	
	site:
		type: String,
		optional: true

	participation:
		type: String,
		optional: true
				
	
	description:
		type: String,
		# label:t("calendar_event_description")
		optional: true,
		autoform:
			rows:2

	ownerId:
		type: String,
		optional: true
		autoform: 
			omit: true,
			defaultValue:->
				return Session.get('userId')	
	
	calendarid:
		type: String,
		# label:t("calendar_event_calendar")
		autoform:
			type: "select"
			#afFieldInput:
			firstOption:false
			defaultValue: ->
				return Session.get("calendarid");
			options: ()->
				options = []
				eventCalendarId = Session.get("eventCalendarId")
				objs = Calendars.find({$or:[{"ownerId":Meteor.userId()},{"members":Meteor.userId()},{"admins":Meteor.userId()}]}).fetch()
				objs.forEach (obj) ->
					options.push
						label: t(obj.title),
						value: obj._id
				calendarids = objs.getProperty("_id")
				calendarObj = Calendars.findOne({_id:eventCalendarId})
				if eventCalendarId and calendarObj
					if _.indexOf(calendarids,eventCalendarId) < 0
						options.push
							label: calendarObj.title,
							value: calendarObj._id
				return options

	remindtimes:
		type: [Number],
		optional: true
		autoform:
			omit:true
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

	eventcolor:
		type: String,
		optional: true
		autoform: 
			omit: true

	calendardata:
		type: String,
		optional: true
		autoform: 
			omit: true

	attendees:
		type:[Object],
		optional:true
		autoform: 
			omit: true
	"attendees.$.role":
		type:String
		optional: true
		defaultValue:"REQ-PARTICIPANT"
	"attendees.$.cutype": 
		type:String
		optional: true
		defaultValue:"INDIVIDUAL"
	"attendees.$.partstat": 
		type:String
		optional: true
		defaultValue:"ACCEPTED"
	"attendees.$.cn": 
		type:String
		optional: true
		autoform:
			defaultValue: ->
				return Meteor.users.findOne({_id:Session.get('userId')}).name
	"attendees.$.mailto": 
		type:String
		optional: true
		autoform:
			defaultValue: ->
				return Meteor.users.findOne({_id:Session.get('userId')}).steedos_id
	"attendees.$.id": 
		type:String
		optional: true
		autoform:
			defaultValue: ->
				return Session.get('userId')
	"attendees.$.description": 
		type:String
		optional: true
	"attendees.$.inviter":
		type:String
		optional: true
	"attendees.$.invitetime":
		type:Date
		optional: true
	"attendees.$.responsetime":
		type:Date
		optional: true
	parentId:
		type:String
		optional: true
		autoform: 
			omit: true
	Isdavmodified:
		type:Boolean
		optional:true
		autoform:
			omit:true
Events.attachSchema Events._simpleSchema

if Meteor.isClient
	Events._simpleSchema.i18n("calendar_objects");

if (Meteor.isServer) 
	Events.allow 
		insert: (userId, doc) ->
			return doc._id

		update: (userId, doc) ->
			return true

		remove: (userId, doc) ->
			return true
	#创建事件之前，为其添加一些属性
	Events.before.insert (userId, doc)->	
		return
	
	Events.after.insert (userId, doc)->
		#Calendar.addChange(doc.calendarid,doc.uri,1);
		return

	Events.before.update (userId, doc, fieldNames, modifier, options) ->
		modifier.$set = modifier.$set || {};
	Events.after.update (userId, doc, fieldNames, modifier, options) ->
		return
	
	
	#删除后的操作，同时删除关联的event事件  after delet
	Events.before.remove (userId, doc)->
		return
if Meteor.isServer
	Events._ensureIndex({
			"end": 1,
			"remindtimes":1
		},{background: true})
	Events._ensureIndex({
			"_id": 1,
		})
	Events._ensureIndex({
			"Isdavmodified": 1,
			"componenttype":1
		},{background: true})
	Events._ensureIndex({
			"uid": 1
		},{background: true})
	Events._ensureIndex({
			"parentId": 1,
			"calendarid":1
		},{background: true})
	Events._ensureIndex({
			"parentId": 1
		},{background: true})
	Events._ensureIndex({
			"calendarid": 1,
			"start":1
		},{background: true})
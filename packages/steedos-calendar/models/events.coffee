@Events = new Mongo.Collection('calendar_objects');
icalendar = require('icalendar');
created = new Date();
# locale = Session.get 'steedos-locale'

Events._simpleSchema = new SimpleSchema
	title:
		type: String
		max: 50
		# label:t("calendar_title")
		label:"标题"
		defaultValue:"新建事件"

	start:  
		type: Date
		# label:t("calendar_event_start")
		label:"开始时间"
		autoform: 
			afFieldInput:
				type:()->
					if Steedos.isMobile()
						return "date"
					else
						return "bootstrap-datetimepicker"
				dateTimePickerOptions:()->
					if Steedos.isMobile()
						return null
					else
						return  {
							language:'zh-cn'
							format:"YYYY-MM-DD HH:mm"
							sideBySide:true
						}
					
	end:  
		type: Date
		# label:t("calendar_event_end")
		label:"结束时间"
		autoform: 
			type:()->
				if Steedos.isMobile()
					return "date"
				else
					return "bootstrap-datetimepicker"
			dateTimePickerOptions:()->
				if Steedos.isMobile()
					return null
				else
					return  {
						language:'zh-cn'
						format:"YYYY-MM-DD HH:mm"
						sideBySide:true
					}


	allDay: 
		type: Boolean
		# label:t("calendar_event_allDay")
		label:"全天"
		defaultValue: false
		optional: true

	calendarid:
		type: String,
		# label:t("calendar_event_calendar")
		label:"所属日历"
		defaultValue: ->
        	return Session.get("calendarid");
		autoform:
			type: "select"
			#afFieldInput:
			firstOption:false
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
		# label:t("calendar_event_description")
		label:"描述"
		optional: true,
		autoform:
			rows:2

	ownerId:  
		type: String,
		optional: true
		autoform: 
			omit: true

	alarms:
		type: [String]
		# label:t("calendar_event_alarms")
		label:"提醒"
		optional: true
		autoform: 
			type: "universe-select"
			multiple: true
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
			sortMethod:"x"
	remindtimes:
		type: [String],
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
	"attendees.$.cutype": 
		type:String
		optional: true
	"attendees.$.partstat": 
		type:String
		optional: true
	"attendees.$.cn": 
		type:String
		optional: true
	"attendees.$.mailto": 
		type:String
		optional: true
	"attendees.$.id": 
		type:String
		optional: true
	"attendees.$.description": 
		type:String
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

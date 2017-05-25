@Events = new Mongo.Collection('calendar_objects');
icalendar = require('icalendar');
uuid = require('uuid');
created = new Date();
Events.attachSchema new SimpleSchema 
	title:  
		type: String,
		label:"会议标题"

	members:  
		type: [String],
		label:"会议成员",
		autoform: 
			type: "universe-select"
			afFieldInput:
				multiple: true
				optionsMethod: "selectGetUsers"

	start:  
		type: Date,
		label:"开始时间",
		autoform: 
			afFieldInput:
				type: "bootstrap-datetimepicker"
				dateTimePickerOptions:
					format: "YYYY-MM-DD HH:mm"
					sideBySide:true
					
	end:  
		type: Date,
		label:"结束时间",
		optional: true,
		autoform: 
			type: "bootstrap-datetimepicker"
			dateTimePickerOptions:
				format: "YYYY-MM-DD HH:mm"
				sideBySide:true


	allDay: 
		type: Boolean,
		label:"全天",
		defaultValue: true,
		optional: true

	calendarid:
		type: String,
		label:"所属日历",
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
				
	# resources:
	# 	type: [String],
	# 	autoform:
	# 		type: "universe-select"
	# 		afFieldInput:
	# 			multiple: true
	# 			optionsMethod: "selectGetUsers"
	
	description:  
		type: String,
		label:"描述",
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
		label:"提醒",
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

	"attendees.$.cutype": 
		type:String

	"attendees.$.partstat": 
		type:String

	"attendees.$.cn": 
		type:String
		optional: true
	"attendees.$.mailto": 
		type:String
	"attendees.$.id": 
		type:String
	"attendees.$.description": 
		type:String
		optional: true
	parentId:
		type:String
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
	#创建事件之前，为其添加一些属性
	Events.before.insert (userId, doc)->
		doc.componenttype = "VEVENT"
		doc._id = uuid();
		doc.uid = doc._id	
		doc.uri = doc._id + ".ics"
		doc.ownerId=userId;
		if _.indexOf(doc.members, userId)==-1
			doc.members.push userId
		attendees=[]
		doc.members.forEach (member)->
			partstat="NEEDS-ACTION"
			steedosId=Meteor.users.findOne({_id:member}).steedos_id
			name=Meteor.users.findOne({_id:member}).name
			attendee = {
				role:"REQ-PARTICIPANT",
				cutype:"INDIVIDUAL",
				partstat:partstat,
				cn:name,
				mailto:steedosId,
				id:member,
				description:null
			}
			if member == doc.ownerId 
				attendee.partstat="ACCEPTED"
			attendees.push attendee  	
		doc.attendees = attendees;
		Calendar.addCalendarObjects(userId,doc,1);
		Meteor.call('updateAttendees',doc,1);		
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

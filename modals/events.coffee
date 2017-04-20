@Events = new Mongo.Collection('calendar_objects');

Events.attachSchema new SimpleSchema 
	title:  
		type: String

	members:  
		type: [String],
		autoform: 
			type: "universe-select"
			afFieldInput:
				multiple: true
				optionsMethod: "inviteGetUsers"

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
		modifier.$set = modifier.$set || {};
		modifier.$unset = modifier.$unset || {};
		
		if modifier.$set.members and modifier.$set.members.indexOf(userId) < 0
			modifier.$set.members.push(userId)

	#添加字段之前，强制给Calendar的OwnerId赋值,且
	Events.before.insert (userId,doc)->
		doc.ownerId=Meteor.userId()
		if doc.members.indexOf(userId) < 0
			 doc.members.push(userId)
		
		doc.components = ["VEVENT", "VTODO"]

	#删除后的操作，同时删除关联的event事件  after delete
	Events.before.remove (userId, doc)->


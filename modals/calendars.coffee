@Calendars = new Mongo.Collection('calendars');

Calendars._simpleSchema = new SimpleSchema 
	title:  
		type: String

	members:  
		type: [String],
		autoform: 
			type: "universe-select"
			afFieldInput:
				multiple: true
				optionsMethod: "selectGetUsers"

	visibility:
		type: String
		allowedValues: ["private"]
		defaultValue: "private"
	
	color:  
		type: String
		autoform:
			type: "bootstrap-minicolors"

	ownerId:  
		type: String,
		optional: true
		autoform:
			omit: true

	synctoken:
		type: Number,
		optional: true
		autoform:
			omit: true

	components:
		type: [String],
		optional: true
		autoform:
			omit: true

Calendars.attachSchema Calendars._simpleSchema

if Meteor.isClient
	Calendars._simpleSchema.i18n("calendars");

if (Meteor.isServer) 
	Calendars.allow 
		insert: (userId, doc) ->
			if userId==""
				return false
			return true

		update: (userId, doc) ->
			if userId!=doc.ownerId
				return false
			return true

		remove: (userId, doc) ->
			if userId!=doc.ownerId
				return false
			return true
	
	Calendars.before.update (userId, doc, fieldNames, modifier, options)->
		modifier.$set = modifier.$set || {};
		modifier.$unset = modifier.$unset || {};
		
		if modifier.$set.members and modifier.$set.members.indexOf(userId) < 0
			modifier.$set.members.push(userId)

	#添加字段之前，强制给Calendar的OwnerId赋值,且
	Calendars.before.insert (userId,doc)->
		doc.ownerId=Meteor.userId()
		if doc.members.indexOf(userId) < 0
			 doc.members.push(userId)
		
		doc.components = ["VEVENT", "VTODO"]

	#删除后的操作，同时删除关联的event事件  after delete
	Calendars.before.remove (userId, doc)->
		# 移除关联的events
		Events.remove({"calendar":doc._id})


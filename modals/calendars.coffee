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
		# 共用方法
	AddOwnerId:(doc)->
			console.log ("addenter")
			isExit=false
			doc.members.forEach (member) ->
				if member==Meteor.userId()
					isExit=true
					return
			if isExit==false
				doc.members.push(Meteor.userId())
			return
	Calendars.before.update (userId, doc)->
		# 移除关联的events
		Events.remove({"calendar":doc._id})
		# //Calendars.AddOwnerId(doc)
		isExit=false
		doc.members.forEach (member) ->
			if member==Meteor.userId()
				isExit=true
				return
		if isExit==false
			doc.members.push(Meteor.userId())
	#添加字段之前，强制给Calendar的OwnerId赋值,且
	Calendars.before.insert (userId,doc)->
		doc.ownerId=Meteor.userId()
		# Calendars.AddOwnerId(doc)
		isExit=false
		doc.members.forEach (member) ->
			if member==Meteor.userId()
				isExit=true
				return
		if isExit==false
			doc.members.push(Meteor.userId())

	#删除后的操作，同时删除关联的event事件  after delete
	Calendars.before.remove (userId, doc)->
		# 移除关联的events
		Events.remove({"calendar":doc._id})


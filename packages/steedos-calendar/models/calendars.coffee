@Calendars = new Mongo.Collection('calendars');
@moment_timezone = require('moment-timezone');
@Defaulttimezone = 'Asia/Shanghai';
@CALENDARCOLORS = new Array("#ac725e","#d06b64","#f83a22","#fa573c","#ff7537","#ffad46",
					"#42d692","#16a765","#7bd148","#b3dc6c","#fbe983","#fad165",
					"#92e1c0","#9fele7","#9fc6e7","#9fc6e7","#4986e7","#9a9cff","#b99aff",
					"#c2c2c2","#cabdbf","#f691b2","#cca6ac","#cd74e6","#a47ae2");
Calendars._simpleSchema = new SimpleSchema 
	title:  
		type: String,
		label:t("calendar_title")
	
  #   space:
  #     type:[String]
  #     type: [String],
		# autoform: 
		#   type: "universe-select"
		#   afFieldInput:
		#       multiple: true
		#       optionsMethod: "selectGetUsers"
	
	# space_permission:
	#   type:String


	members:  
		type: [String],
		label:t("calendar_members")
		defaultValue:[""]
		autoform: 
			type: "universe-select"
			afFieldInput:
				multiple: true
				optionsMethod: "selectGetUsers"
	
	visibility:
		type: String,
		label:t("calendar_visibility")
		allowedValues: ["private"],
		defaultValue: "private"
	
	color:  
		type: String,
		label:t("calendar_color")
		defaultValue: ->
				return  CALENDARCOLORS[parseInt(10000*Math.random())%24]
		autoform:
			type: "bootstrap-minicolors"
			
	ownerId: 
		type: String,
		defaultValue:this.userId
		optional: true
		autoform:
			omit: true

	synctoken:
		type: Number,
		defaultValue:1
		optional: true
		autoform:
			omit: true

	components:
		type: [String],
		defaultValue:["VEVENT","VTODO"]
		optional: true
		autoform:
			omit: true

	timezone:
		type: String,
		autoform: 
			type: "hidden"
			defaultValue: ->
				return moment_timezone.tz.guess()
	isDefault:
		type:Boolean,
		optional: true,
		defaultValue:false
		autoform:
			type:"hidden"

	isResource:
		type: Boolean,
		label:"是否资源",
		defaultValue: false,
		optional: true

	spaceId:
		type: [String],
		label:"所属工作区"
		autoform: 
			type: "universe-select"
			defaultValue：[""]
			afFieldInput:
				multiple: true
				optionsMethod: "selectGetSpaces"
				



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
	#添加字段之前，强制给Calendar的Ownerid赋值,且
	Calendars.before.insert (userId,doc)->
		# doc.ownerId=Meteor.userId()
		# if doc.members.indexOf(userId) < 0
		#    doc.members.push(userId)       
		# doc.components = ["VEVENT","VTODO"]
		# doc.synctoken = 1
		# Meteor.call('calendarinsert',userId,doc);

		return
	#对于一个日历members有几个，就有几个instance
	Calendars.after.insert (userId, doc) ->
		# steedosId = Meteor.users.findOne({_id:userId}).steedos_id;
		# Calendar.addInstance(userId,doc,doc._id,steedosId,1,"","");
		# for member,i in doc.members 
		#   if member != userId
		#       steedosId = Meteor.users.findOne({_id:member})?.steedos_id;
		#       herf="mailto:" + steedosId;
		#       displayname=steedosId;
		#       Calendar.addInstance(userId,doc,doc._id,steedosId,2,herf,displayname);  
		return      
	#更新日历之前，更新instance
	Calendars.before.update (userId, doc, fieldNames, modifier, options)->
		modifier.$set = modifier.$set || {};
		if modifier.$set.members and modifier.$set.members.indexOf(userId) < 0
			modifier.$set.members.push(userId)
		oldMembers = doc.members;
		newMembers = modifier.$set.members;
		addMembers = _.difference newMembers,oldMembers
		subMembers = _.difference oldMembers,newMembers
		for member, i in subMembers
			steedosId = Meteor.users.findOne({_id:member})?.steedos_id
			calendarinstances.remove({"share_displayname":steedosId},{"calendarid":doc._id});
		for member ,i in addMembers
			member = addMembers[i]
			if member != doc.ownerId
				steedosId = Meteor.users.findOne({_id:member})?.steedos_id
				herf="mailto:" + steedosId;
				displayname=steedosId;
				Calendar.addInstance(member,modifier.$set,doc._id,steedosId,2,herf,displayname);
		return
			
	Calendars.after.update (userId, doc, fieldNames, modifier, options)->
		modifier.$set = modifier.$set || {};
		Events.update({calendarid:doc._id},{$set:{eventcolor:doc.color}},{multi:true})
		calendarinstances.update({calendarid:doc._id},{$set:{displayname:doc.title,calendarcolor:doc.color}},{multi:true});
		starttoken = Calendars.findOne({_id:doc._id}).synctoken;
		Calendar.addChange(doc._id, null,2);
		return
	# 移除关联的events,instances,changes
	Calendars.before.remove (userId, doc)->
		Events.remove({"calendarid":doc._id});
		calendarchanges.remove({"calendarid":doc._id});
		calendarinstances.remove({"calendarid" : doc._id}); 
		return

	Calendars.after.remove (userId, doc)->
		
		return




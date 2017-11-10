@Calendars = new Mongo.Collection('calendars');
moment_timezone = require('moment-timezone');
@Defaulttimezone = 'Asia/Shanghai';
@CALENDARCOLORS = new Array("#ff2d55","#ff9500","#ffcc00",
					"#65db39","#34aadc","#cc73e1",
					"#a2845e");
Calendars._simpleSchema = new SimpleSchema 
	title:
		type: String,
		autoform:
			type:"text"
			disabled: ()->
				return Session.get("titleEditable")
			defaultValue: ->
				return t("calendar_add_calendar")

	admins:
		type: [String],
		optional: true,
		autoform:
			disabled: ()->
				if Session.get("titleEditable")
					return Session.get("titleEditable")
				else
					return !Session.get("adminsEditable")
			type: "selectuser"
			multiple: true
			is_within_user_organizations: ->
				is_with = Meteor.settings?.public?.calendar?.user_selection_within_user_organizations
				return !!is_with
			defaultValue: ()->
				return [Meteor.userId()]

	members:  
		type: [String],
		optional: true,
		autoform:
			type: "selectuser"
			disabled: ()->
				return Session.get("titleEditable")
			multiple: true
			is_within_user_organizations: ->
				is_with = Meteor.settings?.public?.calendar?.user_selection_within_user_organizations
				return !!is_with
			defaultValue: ()->
				return [Meteor.userId()]

	members_readonly:
		type: [String],
		optional: true
		autoform:
			type: "selectuser"
			multiple: true
			is_within_user_organizations: ->
				is_with = Meteor.settings?.public?.calendar?.user_selection_within_user_organizations
				return !!is_with
			defaultValue: ()->
				return []

	visibility:
		type: String,
		optional: true,
		#allowedValues: ["private","share"],
		defaultValue: "private"
		autoform:
			omit: true
	
	color:  
		type: String,
		defaultValue: ->
				# count1=Calendars.find({$or:[{"ownerId":Meteor.userId()},{"members":Meteor.userId()}]}).count()
				# count2=calendarsubscriptions.find({principaluri:Meteor.userId()}).count()
				# console.log count1+count2
				# console.log CALENDARCOLORS[(count1+count2)%7]
				return  CALENDARCOLORS[parseInt(10000*Math.random())%7]
		autoform:
			type: "bootstrap-minicolors"

	members_busy:
		type: [String],
		optional: true
		autoform:
			omit: true

	members_busy_pending:
		type: [Object],
		optional: true
		autoform:
			omit: true

	"members_busy_pending.$._id":
		type: String,
		optional: true
		autoform:
			omit: true

	"members_busy_pending.$.name":
		type: String,
		optional: true
		autoform:
			omit: true


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


Calendars.attachSchema Calendars._simpleSchema

if Meteor.isClient
	Calendars._simpleSchema.i18n("calendars");

if (Meteor.isServer) 
	Calendars.allow 
		insert: (userId, doc) ->
			if userId
				return true

		update: (userId, doc) ->
			if userId
				return true

		remove: (userId, doc) ->
			if userId
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
		# 	if member != userId
		# 		steedosId = Meteor.users.findOne({_id:member})?.steedos_id;
		# 		herf="mailto:" + steedosId;
		# 		displayname=steedosId;
		# 		Calendar.addInstance(userId,doc,doc._id,steedosId,2,herf,displayname);  
		# return      
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
			calendarinstances.remove({"share_displayname":steedosId,"calendarid":doc._id});
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
		events=Events.find({"calendarid":doc._id}).fetch()
		events.forEach (event)->
			if event._id==event.parentId
				Events.direct.remove({parentId:event.parentId})
		Events.remove({"calendarid":doc._id});
		calendarchanges.remove({"calendarid":doc._id});
		calendarinstances.remove({"calendarid" : doc._id}); 
		return

	Calendars.after.remove (userId, doc)->		
		return
	if Meteor.isServer
		Calendars._ensureIndex({
			"_id": 1
		})
		Calendars._ensureIndex({
			"ownerId": 1,
			"isDefault":1
		},{background: true})
		Calendars._ensureIndex({
			"_id":1,
			"ownerId": 1
		},{background: true})
		Calendars._ensureIndex({
			"ownerId": 1,
			"members":1
		},{background: true})
		




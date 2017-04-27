@Calendars = new Mongo.Collection('calendars');
jstz = require('jstz');
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
	# 
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
	timezone = jstz.determine();
	
	#添加字段之前，强制给Calendar的OwnerId赋值,且
	Calendars.before.insert (userId,doc)->
		doc.ownerId=Meteor.userId()
		if doc.members.indexOf(userId) < 0
			 doc.members.push(userId)		
		doc.components = ["VEVENT","VTODO"]
		doc.synctoken = 1
	Calendars.after.insert (userId, doc) ->
		#console.log JSON.stringify(doc)
		if doc.visibility == 'private'
			transp = false;
		else
			transp = true;
		steedosId = Meteor.users.findOne({_id:userId}).steedos_id
		console.log "steedosId:#{steedosId}==============="
		calendarinstances.insert
				principaluri:"principals/" + steedosId,
				uri:doc.ownerId,
				transparent:transp,
				access:1,
				share_invitestatus:2,
				calendarid: doc._id,
				displayname:doc.title,
				description:"null",
				timezone:timezone.name(),
				calendarorder:3,
				calendarcolor: doc.color
		Calendar.addChange(doc._id,null,1);
		for member,i in doc.members 
			member = doc.members[i]
			steedosId = Meteor.users.findOne({_id:member})?.steedos_id
			if member != userId
					calendarinstances.insert
						principaluri:"principals/" + steedosId,
						uri:doc.ownerId,
						transparent:transp,
						access:3,
						share_invitestatus:4,
						calendarid: doc._id,
						displayname:doc.title,
						description:"null",
						timezone:timezone.name(),
						calendarorder:3,
						calendarcolor: doc.color,
						share_herf:"mailto:" + steedosId,
						share_displayname: steedosId
					Calendar.addChange(doc._id,null,2);
	#删除后的操作，同时删除关联的event事件  after delete
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

		if doc.visibility == 'private'
			transp = false;
		else
			transp = true;
		for member ,i in addMembers
			member = addMembers[i]
			if member != doc.ownerId
				steedosId = Meteor.users.findOne({_id:member})?.steedos_id
				calendarinstances.insert
					principaluri:"principals/" + steedosId,
					uri:doc.ownerId,
					transparent:transp,
					access:3,
					share_invitestatus:4,
					calendarid: doc._id,
					displayname:doc.title,
					description:"null",
					timezone:timezone.name(),
					calendarorder:3,
					calendarcolor: doc.color,
					share_herf:"mailto:" + steedosId,
					share_displayname: steedosId
		
			
	Calendars.after.update (userId, doc, fieldNames, modifier, options)->
		modifier.$set = modifier.$set || {};
		calendarinstances.update({calendarid:doc._id},{$set:{displayname:doc.title,calendarcolor:doc.color}});

	Calendars.before.remove (userId, doc)->
		# 移除关联的events
	Calendars.after.remove (userId, doc)->
		calendarinstances.remove({"calendarid" : doc._id});
		Events.remove({"calendarid":doc._id});
		calendarchanges.remove({"calendarid":doc._id});




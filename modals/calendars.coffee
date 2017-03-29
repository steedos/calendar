@Calendars = new Mongo.Collection('calendars');

Calendars.attachSchema new SimpleSchema 
	title:  
		type: String
	color:  
		type: String
	members:  
		type: [String],
		optional: true
		autoform: 
			omit: true

	ownerId:  
		type: String,
		optional: true
		autoform: 
			omit: true


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


#添加字段之前，强制给Calendar的OwnerId赋值
Calendars.before.insert (userId,doc)->
	console.log('userid:'+Meteor.userId());
	doc.ownerId=Meteor.userId();

#删除后的操作，同时删除关联的event事件  after delete
Calendars.after.remove (userId, doc)->
	Events.remove({"calendar":doc._id});


	
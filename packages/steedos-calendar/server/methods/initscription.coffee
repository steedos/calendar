Meteor.methods
	initscription: (subscripter) ->
		objs=Calendars.find({$or:[{"ownerId":subscripter},{"members":subscripter}]}).fetch()
		if objs.length==0
			Meteor.call('calendarInit',subscripter,Defaulttimezone)
			objs=Calendars.find({$or:[{"ownerId":subscripter},{"members":subscripter}]}).fetch()
		objs.forEach (obj)->
			if calendarsubscriptions.find({uri:obj._id,principaluri:Meteor.userId()}).count()==0
					calendarsubscriptions.direct.insert
						_id:Calendar.uuid()
						uri:obj._id
						principaluri:Meteor.userId()
						color:obj.color
						calendarname:obj.title
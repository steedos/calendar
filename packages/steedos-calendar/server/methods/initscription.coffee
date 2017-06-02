Meteor.methods
	initscription: (subscripter) ->
		objs=Calendars.find({$or:[{"ownerId":subscripter},{"members":subscripter}]})
		objs.forEach (obj)->
			calendarsubscriptions.direct.insert
				_id:Calendar.uuid()
				uri:obj._id
				principaluri:Meteor.userId()
				color:obj.color
				calendarname:obj.title
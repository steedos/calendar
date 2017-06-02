Meteor.methods
	initscription: (subscripter) ->
		objs=Calendars.find({$or:[{"ownerId":subscripter},{"members":subscripter}]})
		objs.forEach (obj)->
			if calendarsubscriptions.find({uri:obj._id,principaluri:Meteor.userId()}).count()==0
					console.log "1111"
					calendarsubscriptions.direct.insert
						_id:Calendar.uuid()
						uri:obj._id
						principaluri:Meteor.userId()
						color:obj.color
						calendarname:obj.title
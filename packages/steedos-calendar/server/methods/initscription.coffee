Meteor.methods
	initscription: (subscripter) ->
		obj=Calendars.findOne({ownerId:subscripter},{isDefault:true})
		console.log obj
		if !obj
			Meteor.call('calendarInit',subscripter,Defaulttimezone)
			obj=Calendars.findOne({ownerId:subscripter},{isDefault:true})
		if calendarsubscriptions.find({uri:obj._id,principaluri:Meteor.userId()}).count()==0
				calendarsubscriptions.direct.insert
					_id:Calendar.uuid()
					uri:obj._id
					principaluri:Meteor.userId()
					color:obj.color
					calendarname:obj.title
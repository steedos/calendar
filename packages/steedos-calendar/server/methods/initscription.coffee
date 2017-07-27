Meteor.methods
	initscription: (subscripter) ->
		obj=Calendars.findOne({ownerId:subscripter},{isDefault:true})
		if !obj
			Meteor.call('calendarInit',subscripter,Defaulttimezone)
			obj=Calendars.findOne({ownerId:subscripter},{isDefault:true})

		membersBusy = obj.members_busy

		if membersBusy and _.indexOf(membersBusy,this.userId) >= 0
			if calendarsubscriptions.find({uri:obj._id,principaluri:Meteor.userId()}).count()==0
					calendarsubscriptions.direct.insert
						_id:Calendar.uuid()
						uri:obj._id
						principaluri:Meteor.userId()
						color:obj.color
						calendarname:obj.title
		else
			# userName = db.users.findOne({_id:this.userId}).name
			
			# Calendars.update(
			# 	{ownerId:subscripter,isDefault:true},
			# 	{$set:{}}
			# )
			return
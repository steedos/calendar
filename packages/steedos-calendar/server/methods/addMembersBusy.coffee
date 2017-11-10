Meteor.methods
	addMembersBusy: (members,defaultcalendarid)->
		defaultCalendarObj = Calendars.findOne({_id:defaultcalendarid})
		oldMembersBusy = defaultCalendarObj?.members_busy || []
		newMembersBusy = members
		subMembersBusy = _.difference(oldMembersBusy,newMembersBusy)
		if subMembersBusy.length > 0
			subMembersBusy.forEach (submember,index) ->
				calendarsubscriptions.remove({uri:defaultcalendarid,principaluri:submember})
		Calendars.update(
			{_id: defaultcalendarid},
			{
				$set: {members_busy: members}
			}
		)
		return members



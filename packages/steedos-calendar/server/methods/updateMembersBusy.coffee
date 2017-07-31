Meteor.methods
	updateMembersBusy:(memberIds,action) ->
		userId = this.userId
		defaultCalendarObj = Calendars.findOne({ownerId:userId,isDefault:true})
		membersBusy = defaultCalendarObj.members_busy || []
		membersBusyPending = defaultCalendarObj.members_busy_pending
		membersBusyPendingIds = membersBusyPending.getProperty("_id")
		memberIds.forEach (memberId) ->
			index = _.indexOf(membersBusyPendingIds,memberId)
			if index >= 0
				membersBusyPending.remove(index)
				membersBusyPendingIds.remove(index)

		if action == "accept"
			membersBusy = membersBusy.concat(memberIds)
			Calendars.update(
				{_id:defaultCalendarObj._id}
				{
					$set:{members_busy:membersBusy,members_busy_pending:membersBusyPending}
				}
			)
			memberIds.forEach (memberId) ->
				calendarsubscriptions.direct.insert
					_id:Calendar.uuid()
					uri:defaultCalendarObj._id
					principaluri:memberId
					color:defaultCalendarObj.color
					calendarname:defaultCalendarObj.title

		if action == "refuse"
			Calendars.update(
				{_id:defaultCalendarObj._id}
				{
					$set:{members_busy_pending:membersBusyPending}
				}
			)
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
			membersBusy = _.uniq(membersBusy.concat(memberIds))
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

				payload = 
					app: 'calendar'
					id: memberId
				userName = db.users.findOne({_id:userId}).name
				title = "您的订阅申请已通过"
				text = "#{userName}已接受您的订阅申请"
				Push.send
					createdAt: new Date(),
					createdBy: '<SERVER>',
					from: 'calendar',
					title: title,
					text: text,
					payload: payload,
					badge: 12,
					query: {userId:memberId,appName:"calendar"}

		if action == "refuse"
			Calendars.update(
				{_id:defaultCalendarObj._id}
				{
					$set:{members_busy_pending:membersBusyPending}
				}
			)
			memberIds.forEach (memberId) ->
				payload = 
					app: 'calendar'
					id: memberId
				userName = db.users.findOne({_id:userId}).name
				title = "您的订阅申请未能通过"
				text = "#{userName}拒绝了您的订阅申请"
				Push.send
					createdAt: new Date(),
					createdBy: '<SERVER>',
					from: 'calendar',
					title: title,
					text: text,
					payload: payload,
					badge: 12,
					query: {userId:memberId,appName:"calendar"}
import { Calendar } from '../main';
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
				member = db.users.findOne({_id:memberId}, {fields: {mobile: 1, utcOffset: 1, locale: 1, name: 1}})
				lang = 'en'
				if member.locale is 'zh-cn'
					lang = 'zh-CN'
				payload = 
					app: 'workflow'
					id: memberId
					url:"/calendar"
					host:Meteor.absoluteUrl().substr(0, Meteor.absoluteUrl().length-1)
				userName = db.users.findOne({_id:userId}).name
				title = TAPi18n.__("calendar_subscript_success", {}, lang)
				text = TAPi18n.__("calendar_subscript_success_text", {username:userName}, lang)
				Push.send
					createdAt: new Date(),
					createdBy: '<SERVER>',
					from: 'workflow',
					title: title,
					text: text,
					payload: payload,
					badge: 12
					query: {userId:memberId,appName:"workflow"}

		if action == "refuse"
			Calendars.update(
				{_id:defaultCalendarObj._id}
				{
					$set:{members_busy_pending:membersBusyPending}
				}
			)
			memberIds.forEach (memberId) ->
				member = db.users.findOne({_id:memberId}, {fields: {mobile: 1, utcOffset: 1, locale: 1, name: 1}})
				lang = 'en'
				if member.locale is 'zh-cn'
					lang = 'zh-CN'
				payload = 
					app: 'workflow'
					id: memberId
					url:"/calendar"
					host:Meteor.absoluteUrl().substr(0, Meteor.absoluteUrl().length-1)
				userName = db.users.findOne({_id:userId}).name
				title = TAPi18n.__("calendar_subscript_fail", {}, lang)
				text = TAPi18n.__("calendar_subscript_fail_text", {username:userName}, lang)
				Push.send
					createdAt: new Date(),
					createdBy: '<SERVER>',
					from: 'workflow',
					title: title,
					text: text,
					payload: payload,
					badge: 12
					query: {userId:memberId,appName:"workflow"}
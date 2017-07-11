Meteor.methods
	shareCalendar: (calendarObj)->
		shareMembers = calendarObj?.members_readonly
		shareMembers.forEach (memberId) ->
			if calendarsubscriptions.find({uri:calendarObj._id,principaluri:memberId}).count()==0
				calendarsubscriptions.direct.insert
					_id:Calendar.uuid()
					uri:calendarObj._id
					principaluri:memberId
					color:calendarObj.color
					calendarname:calendarObj.title
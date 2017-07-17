Meteor.methods
	shareCalendar: (calendarObj,option)->
		shareMembersIds = calendarObj?.members_readonly
		if option == "new"
			addMembersIds = shareMembersIds
		else if option == "update"
			newMembersIds = calendarObj?.members_readonly
			oldMembersIds = calendarsubscriptions.find({uri:calendarObj._id}).fetch().getProperty("principaluri")
			addMembersIds = _.difference(newMembersIds,oldMembersIds)
			subMembersIds = _.difference(oldMembersIds,newMembersIds)
			if subMembersIds?.length > 0
				subMembersIds.forEach (memberId) ->
					calendarsubscriptions.remove({uri:calendarObj._id,principaluri:memberId})
		if addMembersIds?.length > 0
			addMembersIds.forEach (memberId) ->
				if calendarsubscriptions.find({uri:calendarObj._id,principaluri:memberId}).count()==0
					calendarsubscriptions.direct.insert
						_id:Calendar.uuid()
						uri:calendarObj._id
						principaluri:memberId
						color:calendarObj.color
						calendarname:calendarObj.title
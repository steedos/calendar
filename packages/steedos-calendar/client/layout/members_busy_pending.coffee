Template.members_busy_pending_modal.helpers
	members: ()->
		defaultCalendarId = Session.get "defaultcalendarid"
		members = Calendars.findOne({_id:defaultCalendarId}).members_busy_pending || []
		return members

Template.members_busy_pending_modal.events
	'click .btn-accept':(event) ->
		memberId = this._id
		Meteor.call("updateMembersBusy",memberId,"accept",
			(error,result)->
				if error
					console.log error
		)

	'click .btn-refuse':(event) ->
		memberId = this._id
		Meteor.call("updateMembersBusy",memberId,"refuse",
			(error,result)->
				if error
					console.log error
		)

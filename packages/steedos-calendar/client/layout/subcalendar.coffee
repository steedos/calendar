Template.subcalendar_modal.onRendered ->

Template.subcalendar_modal.helpers
	subCalendars: ()->
		userId = Meteor.userId()
		if Calendars.find({members_readonly:userId}).count() > 0
			return Calendars.find({members_readonly:userId}).fetch()
		else
			return false	
		

	isCalendarSub: (calendarId)->
		if calendarsubscriptions.find({uri:calendarId}).count()
			return true
		else
			return false

Template.subcalendar_modal.events
	'click .sub-calendar-box':(event) ->
		calendarObj = 
			_id: this._id
			title: this.title
			color: this.color
		Meteor.call("subCalendar",calendarObj,"sub",
			(error,result)->
				if !error and result
					calendarIds = Session.get("calendarIds")
					calendarIds = _.without(calendarIds,result)
					Session.set("calendarIds",calendarIds)
					localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
		)

	'click .sub-calendar-title':(event) ->
		calendarObj = 
			_id: this._id
			title: this.title
			color: this.color
		Meteor.call("subCalendar",calendarObj,"check",
			(error,result)->
				if !error
					Session.set("calendarIds",[result])
					localStorage.setItem("calendarIds:"+Meteor.userId(),[result])
					$('[data-dismiss="modal"]').click()
		)
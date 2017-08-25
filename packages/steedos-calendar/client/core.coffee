@moment_timezone = require('moment-timezone');

Meteor.startup ->
	if Meteor.isClient
		Tracker.autorun ()->
			if Meteor.userId()
				Meteor.call('calendarInit',Meteor.userId(),moment_timezone.tz.guess())

		Tracker.autorun ()->
			if Steedos.getAccountZoomValue()
				$(window).trigger("resize")

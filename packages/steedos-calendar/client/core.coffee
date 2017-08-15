@moment_timezone = require('moment-timezone');

Meteor.startup ->
	Tracker.autorun ()->
		if Meteor.userId()
			Meteor.call('calendarInit',Meteor.userId(),moment_timezone.tz.guess())



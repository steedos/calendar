@moment_timezone = require('moment-timezone');

Tracker.autorun ()->
	Steedos.Helpers.setAppTitle(t "Steedos Calendar");

Meteor.startup ->
	Tracker.autorun ()->
		if Meteor.userId()
			Meteor.call('calendarInit',Meteor.userId(),moment_timezone.tz.guess())

	Tracker.autorun ()->
		if Steedos.getAccountZoomValue()
			$(window).trigger("resize")

	$("body").removeClass("skin-blue").addClass("skin-blue-light")

Meteor.startup ->
	if Meteor.isClient
		db.apps.INTERNAL_APPS = []
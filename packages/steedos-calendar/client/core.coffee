@moment_timezone = require('moment-timezone');

Tracker.autorun ()->
	if Session.get("steedos-locale") == "zh-cn"
		TAPi18n.setLanguage("zh-CN")
	else
		TAPi18n.setLanguage("en")		
	
	Steedos.Helpers.setAppTitle(t "Steedos Calendar");

Meteor.startup ->
	Tracker.autorun ()->
		if Meteor.userId()
			Meteor.call('calendarInit',Meteor.userId(),moment_timezone.tz.guess())


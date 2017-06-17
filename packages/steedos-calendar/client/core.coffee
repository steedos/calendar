@moment_timezone = require('moment-timezone');

Meteor.startup ->
	$("body").css("background-image", "url('/packages/steedos_theme/client/background/birds.jpg')");
	
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


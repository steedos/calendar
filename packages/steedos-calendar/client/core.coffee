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

	Tracker.autorun ()->
		if Steedos.getAccountZoomValue()
			$(window).trigger("resize")
			
Meteor.startup ->
	if Meteor.isClient
		$("body").removeClass("skin-blue").addClass("skin-blue-light")
		db.apps.INTERNAL_APPS = []
		# Tracker.autorun ()->
		# 	if !Meteor.userId() and !Meteor.loggingIn()
		# 		# # 这里不可以用FlowRouter.go '/steedos/sign-in';，因为会跳转到/calendar/steedos/sign-in
		# 		location.href = "/steedos/sign-in"
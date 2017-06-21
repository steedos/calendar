@moment_timezone = require('moment-timezone');

Tracker.autorun ()->
	if Session.get("steedos-locale") == "zh-cn"
		TAPi18n.setLanguage("zh-CN")
	else
		TAPi18n.setLanguage("en")		
	
	Steedos.Helpers.setAppTitle(t "Steedos Calendar");

Meteor.startup ->
	if Meteor.isClient
		# 因日历中fullCalendar控件在大字体下拖动新建事件有BUG，这里暂时禁用浏览器中的大字体功能
		unless Steedos.isNode()
			Steedos.applyAccountZoomValue = ->
	Tracker.autorun ()->
		if Meteor.userId()
			Meteor.call('calendarInit',Meteor.userId(),moment_timezone.tz.guess())


import 'sweetalert/dist/sweetalert-dev.js'
import 'sweetalert/dist/sweetalert.css'
@moment_timezone = require('moment-timezone');
@Calendar = {}

Meteor.startup ->
	Steedos.API.setAppTitle("Steedos Calendar");
	$("body").css("background-image", "url('/packages/steedos_theme/client/background/birds.jpg')");

Tracker.autorun ()->
	if Session.get("steedos-locale") == "zh-cn"
		TAPi18n.setLanguage("zh-CN")
	else
		TAPi18n.setLanguage("en")		

Tracker.autorun ()->
	if Meteor.userId()
		Meteor.call('calendarInit',moment_timezone.tz.guess())

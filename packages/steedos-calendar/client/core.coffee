@moment_timezone = require('moment-timezone');

loginWithCookie = (onSuccess) ->
	userId = getCookie("X-User-Id")
	authToken = getCookie("X-Auth-Token")
	if userId and authToken
		if Meteor.userId() != userId
			Accounts.connection.setUserId(userId);
			Accounts.loginWithToken authToken,  (err) ->
				if (err)
					Meteor._debug("Error logging in with token: " + err);
					Accounts.makeClientLoggedOut();
				else if onSuccess
					onSuccess();

getCookie = (name)->
	pattern = RegExp(name + "=.[^;]*")
	matched = document.cookie.match(pattern)
	if(matched)
		cookie = matched[0].split('=')
		return cookie[1]
	return false

Meteor.startup ->
	$("body").css("background-image", "url('/packages/steedos_theme/client/background/birds.jpg')");
	
Tracker.autorun ()->
	if Session.get("steedos-locale") == "zh-cn"
		TAPi18n.setLanguage("zh-CN")
	else
		TAPi18n.setLanguage("en")		
	
	Steedos.Helpers.setAppTitle("Steedos Calendar");

Meteor.startup ->
	if (!Accounts._storedUserId())
		loginWithCookie ()->
			FlowRouter.go "/calendar"

	Tracker.autorun ()->
		if Meteor.userId()
			Meteor.call('calendarInit',Meteor.userId(),moment_timezone.tz.guess())


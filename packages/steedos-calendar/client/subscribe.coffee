calendarsSub = new SubsManager();

Meteor.startup ->
	calendarsSub.subscribe "calendars"
	calendarsSub.subscribe "subcalendars"
	# Tracker.autorun ->
	# 	calendarsSub.subscribe "calendars_members", Session.get("calendarId")

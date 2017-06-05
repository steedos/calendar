calendarsSub = new SubsManager();

Meteor.startup ->
	calendarsSub.subscribe "calendars"
	calendarsSub.subscribe "subcalendars"
	# Tracker.autorun ->
	# 	calendarsSub.subscribe "calendars_members", Session.get("calendarId")


Tracker.autorun (c)->
	if calendarsSub.ready()
		if localStorage.getItem("calendarid:"+Meteor.userId())==null
			calendar=Calendars.find({isDefault:true}).fetch()
			console.log calendar
			localStorage.setItem("calendarid:"+Meteor.userId(),calendar[0]._id)
		#Session.set("calendarid",1ocalStorage.getItem("calendarid"))
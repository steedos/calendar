calendarsSub = new SubsManager();

Meteor.startup ->
	calendarsSub.subscribe "calendars"
	calendarsSub.subscribe "subcalendars"
	# Tracker.autorun ->
	# 	calendarsSub.subscribe "calendars_members", Session.get("calendarId")


Tracker.autorun (c)->
	if calendarsSub.ready()
		if localStorage.getItem("calendarid:"+Meteor.userId())==null
			defaultcalendar=Calendars.find({isDefault:true}).fetch()
			console.log calendar
			localStorage.setItem("calendarid:"+Meteor.userId(),defaultcalendar[0]?._id)
		Session.set("calendarid",localStorage.getItem("calendarid:"+Meteor.userId()))
		calendarIds = []
		if localStorage.getItem("calendarIds:"+Meteor.userId())==null
			objs = Calendars.find({isDefault:true,ownerId:Meteor.userId()}).fetch()
			objs.forEach (obj) ->
				console.log obj.title
				calendarIds.push(obj._id)

			# resources = calendarsubscriptions.find().fetch()
			# resources.forEach (resource) ->
			# 	console.log resource.uri
			# 	calendarIds.push(resource.uri)
			localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
		#localStorage.getItem("calendarIds:"+Meteor.userId())
		calendarIdsString=localStorage.getItem("calendarIds:"+Meteor.userId())
		calendarIds=calendarIdsString.split(",")
		Session.set('calendarIds',calendarIds)	


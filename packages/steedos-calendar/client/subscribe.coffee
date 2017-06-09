calendarsSub = new SubsManager();

Meteor.startup ->
	calendarsSub.subscribe "calendars"
	calendarsSub.subscribe "subcalendars"
	calendarsSub.subscribe "reminders"			
	Session.set('Intervaltime',10*1000)
	setInterval(
		()->
			defaultcalendarid=Session.get('defaultcalendarid')
			if defaultcalendarid
				events=Events.find({calendarid:defaultcalendarid}).fetch()
				currenttime=moment()
				if events
					events.forEach (event)->
						tempReminders = []
						if event.remindtimes
							#console.log event.remindtimes
							event.remindtimes.forEach (remindtime)->
								if remindtime-currenttime._d<=0
									#swal(event.title,"开始时间"+event.start,"warning")
									remindtimes=event.remindtimes
									swal({
										  title: event.title,
										  text: "开始时间"+event.start,
										  type: "warning",
										  showCancelButton: true,
										  cancelButtonText:"关闭",
										  confirmButtonColor: "#DD6B55",
										  confirmButtonText: "稍后提醒",
										  closeOnConfirm: true,
										  closeOnCancel: true,
										  html: false
										},
										(closeOnConfirm)->	
											if closeOnConfirm
												newremindtime=moment().valueOf()+5*60*1000
												indexOf=_.indexOf(remindtimes,remindtime);
												remindtimes[indexOf]=newremindtime;
												#setTimeout('showReminders', 5*60*1000)
											else
												indexOf = _.indexOf(remindtimes,remindtimes);
												remindtimes.splice(indexOf,1);
											console.log remindtimes
											Events.direct.update({_id:event._id},{$set:{remindtimes:remindtimes}})
											
										);
		10*1000)																
		
		#setTimeout('showReminders', 10*1000)
	# Tracker.autorun ->
	# 	calendarsSub.subscribe "calendars_members", Session.get("calendarId")
	#showReminders()

Tracker.autorun (c)->
	if calendarsSub.ready()
		if localStorage.getItem("calendarid:"+Meteor.userId())==null
			defaultcalendar=Calendars.find({isDefault:true}).fetch()
			localStorage.setItem("calendarid:"+Meteor.userId(),defaultcalendar[0]?._id)
		Session.set("calendarid",localStorage.getItem("calendarid:"+Meteor.userId()))
		calendarIds = []
		if !localStorage.getItem("calendarIds:"+Meteor.userId())
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
		defaultcalendar=Calendars.findOne({ownerId:Meteor.userId()},{isDefault:true}, {fields:{_id: 1,color:1}})
		Session.set('defaultcalendarid',defaultcalendar._id)
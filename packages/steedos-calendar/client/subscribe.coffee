calendarsSub = new SubsManager();
Meteor.startup ->
	calendarsSub.subscribe "calendars"
	calendarsSub.subscribe "subcalendars"
	calendarsSub.subscribe "reminders"
	isRemindlater=false
	setInterval(
		()->
			defaultcalendarid=Session.get('defaultcalendarid')
			if defaultcalendarid
				events=Events.find({calendarid:defaultcalendarid}).fetch()
				currenttime=moment()
				if events
					events.forEach (event)->
						tempReminders = []
						if event.remindtimes and event.end-currenttime._d>0
							event.remindtimes.forEach (remindtime)->
								if remindtime-currenttime._d<=0 and !Session.get(event._id+":isRemindlater")
									remindtimes=event.remindtimes
									subdays =event.start.getDate()-currenttime._d.getDate()
									if subdays==0
										if event.start.getHours()>=12
											remindText="定于下午"+moment(event.start).format("hh:mm")
										else
											remindText="定于上午"+moment(event.start).format("hh:mm")
									else if subdays==1
											if event.start.getHours()>=12
												remindText="定于明天下午"+moment(event.start).format("hh:mm")
											else
												remindText="定于明天上午"+moment(event.start).format("hh:mm")
										else
											if event.start.getHours()>=12
												remindText="定于后天下午"+moment(event.start).format("hh:mm")
											else
												remindText="定于后天上午"+moment(event.start).format("hh:mm")
									swal({
										  title: event.title,
										  text: remindText,
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
												isRemindlater=true
												Session.set(event._id+":isRemindlater",isRemindlater);
												setTimeout(
													()->
														isRemindlater=false
														Session.set(event._id+":isRemindlater",isRemindlater); 
													,5*60*1000)
											else
												indexOf = _.indexOf(remindtimes,remindtimes);
												remindtimes.splice(indexOf,1);
											Events.direct.update({_id:event._id},{$set:{remindtimes:remindtimes}})
											
										);
		,10*1000)																

	setInterval(
		()->
			Meteor.call('davModifiedEvent')
		,30*1000)
Tracker.autorun (c)->
	if calendarsSub.ready()
		$("body").removeClass("loading")
		if localStorage.getItem("calendarid:"+Meteor.userId())
			selectCalendar=Calendars.findOne({_id:localStorage.getItem("calendarid:"+Meteor.userId())})
			if !selectCalendar
				defaultcalendar=Calendars.find({isDefault:true}).fetch()
				localStorage.setItem("calendarid:"+Meteor.userId(),defaultcalendar[0]?._id)
		else
			defaultcalendar=Calendars.find({isDefault:true}).fetch()
			localStorage.setItem("calendarid:"+Meteor.userId(),defaultcalendar[0]?._id)
		Session.set("calendarid",localStorage.getItem("calendarid:"+Meteor.userId()))
		calendarIds = []
		if !localStorage.getItem("calendarIds:"+Meteor.userId())
			objs = Calendars.find({isDefault:true,ownerId:Meteor.userId()}).fetch()
			objs.forEach (obj) ->
				calendarIds.push(obj._id)
			localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
		#localStorage.getItem("calendarIds:"+Meteor.userId())
		calendarIdsString=localStorage.getItem("calendarIds:"+Meteor.userId())
		calendarIds=calendarIdsString.split(",")
		Session.set('calendarIds',calendarIds)	
		defaultcalendar=Calendars.findOne({ownerId:Meteor.userId()},{isDefault:true}, {fields:{_id: 1,color:1}})
		Session.set('defaultcalendarid',defaultcalendar?._id)
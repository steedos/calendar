@calendarsSub = new SubsManager();
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
						remindtimes = event.remindtimes
						attendeesid=_.pluck(event.attendees,'id');
						dx=attendeesid.indexOf(Meteor.userId())
						if dx < 0
							state = false
						else
							state = event.attendees[dx]?.partstat=='ACCEPTED'
						if remindtimes and event.end - currenttime._d>0 and state
							remindtimes.forEach (remindtime)->
								if remindtime-currenttime._d<=0 and !Session.get(event._id+":isRemindlater")
									subdays =event.start.getDate()-currenttime._d.getDate()
									if subdays==0
										if event.start.getHours()>=12
											remindText=t("call_at_pm",moment(event.start).format("hh:mm"))
										else
											remindText=t("call_at_am",moment(event.start).format("hh:mm"))
									else if subdays==1
											if event.start.getHours()>=12
												remindText=t("call_at_tomorrow_pm",moment(event.start).format("hh:mm"))
											else
												remindText=t("call_at_tomorrow_am",moment(event.start).format("hh:mm"))
										else if subdays==2
											if event.start.getHours()>=12
												remindText=t("call_at_the_day_after_tomorrow_pm",moment(event.start).format("hh:mm"))
											else
												remindText=t("call_at_the_day_after_tomorrow_am",moment(event.start).format("hh:mm"))
									swal({
										  title: event.title+remindText,
										  #text: '',
										  type: "warning",
										  showCancelButton: true,
										  cancelButtonText:t("close"),
										  confirmButtonColor: "#DD6B55",
										  confirmButtonText: t("remind_me_later"),
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

Tracker.autorun (c)->
	
	if calendarsSub.ready()	
		calendarid = Session.get "defaultcalendarid"	
		if calendarid	
			calendarsSub.subscribe "event-need-action",calendarid

		currentCalendarIds = Session.get "calendarIds"
		currentCalendarIds.forEach (currentCalendarId,index) ->
			if !Calendars.findOne({_id: currentCalendarId}) and !calendarsubscriptions.findOne({uri:currentCalendarId})
				currentCalendarIds.remove(index)
				Session.set "calendarid", calendarid
				localStorage.setItem("calendarid:"+Meteor.userId(),calendarid)

		Session.set 'calendarIds', currentCalendarIds
		localStorage.setItem("calendarIds:"+Meteor.userId(),currentCalendarIds)

Tracker.autorun (c) ->
	userId = Meteor.userId()
	calendarid = Session.get("defaultcalendarid")
	if calendarid and calendarsSub.ready()
		selector = 
		{
			calendarid: calendarid,
			"attendees": {
				$elemMatch: {
					id: userId,
					partstat: "NEEDS-ACTION"
				}
			}
		}
		if Events.find(selector).count()
			FlowRouter.go '/inbox'
			toastr.info t("you_have_invitation_to_feedback_please_fill_in_the_invitation")
		c.stop()

Tracker.autorun (c) ->
	if calendarsSub.ready()
		userId = Meteor.userId()
		calendarid = Session.get("defaultcalendarid")
		calendarObj = Calendars.findOne({_id:calendarid})
		membersBusyPending = calendarObj.members_busy_pending
		if membersBusyPending?.length > 0
			Modal.show("members_busy_pending_modal")




import moment from 'moment'
import Calendar from '../core'

@moment = moment

Template.calendarContainer.onRendered ->
	Calendar.generateCalendar();

eventsDep = new Tracker.Dependency
eventsSub = new SubsManager()

eventsRange = null
eventsLoading = false 

Calendar.reloadEvents = () ->
	eventsDep.depend()
	$("#calendar").fullCalendar("refetchEvents")


Calendar.getEventsData = ( start, end, timezone, callback )->
	if !Meteor.userId()
		callback([])
		return
	calendarIds=Session.get('calendarIds')
	if !calendarIds
		calendarIds=[]
	calendar=Calendars.findOne({'_id':Session.get('calendarid')})
	$('#calendar').fullCalendar("getCalendar").getView().options.eventColor=calendar?.color
	params = 
		start: start.toDate()
		end: end.toDate()
		timezone: timezone
		calendar:calendarIds

	eventsSub.subscribe "calendar_objects", params
	Tracker.autorun (c)->
		if eventsSub.ready()
			unless $("[data-toggle=offcanvas]").length 
				$("#calendar .fc-header-toolbar .fc-left").prepend('<button type="button" class="btn btn-default" data-toggle="offcanvas"><i class="fa fa-bars"></i></button>')
			unless $("button.btn-add-event").length
				$(".fc-button-group").prepend('<button type="button" class="btn btn-default btn-add-event"><i class="ion ion-plus-round"></i></button>')
			events = Events.find(calendarid:{$in: params.calendar}).fetch()
			callback(events)				
			c.stop()

Calendar.hasPermission = ( event )->
	obj = Events.findOne({'_id':event._id})
	if (obj?.ownerId==Meteor.userId()&&obj?.parentId==obj?._id)
		return true
	else
		return false

Calendar.generateCalendar = ()->
	if !$('#calendar').children()?.length
		if Steedos.isMobile()
			rightHeaderView = 'month,agendaDay'
			defaultView = 'month'
		else
			rightHeaderView = 'month,agendaWeek,agendaDay,listWeek'
			defaultView = 'agendaWeek'
		$('#calendar').fullCalendar
			height: ()->
				return $('#calendar').height() - 2
			handleWindowResize: true
			header: 
				left: ''
				center: 'prev title next'
				right: rightHeaderView
			selectable: true
			selectHelper: true
			# weekends:false
			navLinks: true
			editable: true
			eventLimit: true
			weekNumbers:false
			nowIndicator: true
			defaultView:defaultView
			events: Calendar.getEventsData
			timeFormat: 'H:mm'
			timezone: 'local'
			locale: Session.get('steedos-locale')
			noEventsMessage:t("no_events_message")
			buttonText:
				listWeek:t("calendar_list_week")
			# businessHours:
			# 	dow: [1,2,3,4,5],
			# 	start:'08:00'
			# 	end:'18:00'

			eventDataTransform: (event) ->
				calendar = Calendars.findOne({'_id':event.calendarid})
				color = ""
				if calendar
					color = calendar.color
					title = event.title
				else
					cs = calendarsubscriptions.findOne({'uri':event.calendarid})
					color = cs?.color
					title = ""
				copy =
					id: event._id
					allDay: event.allDay
					title: title
					url:event.url
					color:color
					backgroundColor:color
					borderColor:color
				if event.start
					copy.start = moment(event.start)
				if event.end
					copy.end = moment(event.end)
				return copy
			
			select: (start, end, jsEvent, view, resource)->
				# calendarIds = []
				# calendarid = Session.get "calendarid"
				# calendarIds.push calendarid
				# checkBox = $(event.currentTarget.childNodes[1])
				# checkBox.addClass("fa-check")
				# localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
				# Session.set 'calendarIds',calendarIds
				# Calendar.reloadEvents()
				#$('body').addClass "loading"
				objs = Calendars.find()
				calendarid = Session.get('calendarid')
				if calendarid==undefined
					objs.forEach (obj) ->
						if obj.isDefault
							calendarid = obj._id
				calendarIds=Session.get('calendarIds')
				if calendarIds.indexOf(calendarid)<0
					calendarIds.push(calendarid)
					Session.set('calendarIds',calendarIds)
					localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
				Session.set "startTime",start.toDate()
				Session.set "endTime",end.toDate()
				Session.set 'userId',Meteor.userId()
				attendees=[]
				userId= Meteor.userId()
				attendee = {
					role:"REQ-PARTICIPANT",
					cutype:"INDIVIDUAL",
					partstat:"ACCEPTED",
					cn:Meteor.users.findOne({_id:userId}).name,
					mailto:Meteor.users.findOne({_id:userId}).steedos_id,
					id:userId,
					description:null
				}
				attendees.push attendee
				
				doc = {
					calendarid:calendarid,
					ownerId:Meteor.userId(),
					attendees:attendees
				}
				Modal.show('event_detail_modal',doc)

			eventClick: (calEvent, jsEvent, view)->
				event = Events.findOne
					_id: calEvent?.id
				if event
					AutoForm.resetForm("eventsForm")
					Modal.show('event_detail_modal', event)
			eventDrop: (event, delta, revertFunc)->
				hasPermission = Calendar.hasPermission(event)
				if !hasPermission
					swal(t("calendar_no_permission"),t("calnedar_no_permission_modify_event"),"warning");
					Calendar.reloadEvents()
					return

				obj = Events.findOne({'_id':event._id})
				obj.start = moment(event.start._d).toDate()
				obj.end = moment(event.end._d).toDate()
				Meteor.call('updateEvents',obj,2)

				#Meteor.call('updateEvents',)
			eventResize: (event, delta, revertFunc, jsEvent, ui, view)->
				hasPermission = Calendar.hasPermission(event)
				if !hasPermission
					swal(t("calendar_no_permission"),t("calnedar_no_permission_modify_event"),"warning");
					Calendar.reloadEvents()
					return
				obj = Events.findOne({'_id':event._id})
				obj.start = moment(event.start._d).toDate()
				obj.end = moment(event.end._d).toDate()
				Meteor.call('updateEvents',obj,2)
			#eventAfterAllRender:(view)->
				
		Events.find().observe
			added: (id, fields) ->
				eventsDep.changed();
			changed: () ->
				eventsDep.changed();
			removed: () ->
				eventsDep.changed();

		Tracker.autorun ()->
			Calendar.reloadEvents();

	else
		Calendar.reloadEvents();


Template.calendarContainer.events
	'click button.btn-add-event': ()->
		calendarid = Session.get 'calendarid'
		start = new Date()
		end = new Date()
		attendees=[]
		userId = Meteor.userId()
		attendee = {
			role:"REQ-PARTICIPANT",
			cutype:"INDIVIDUAL",
			partstat:"ACCEPTED",
			cn:Meteor.users.findOne({_id:userId}).name,
			mailto:Meteor.users.findOne({_id:userId}).steedos_id,
			id:userId,
			description:null
		}
		attendees.push attendee
		
		doc = {
			start: start,
			end: end,
			calendarid:calendarid,
			ownerId:userId,
			attendees:attendees
		}
		Modal.show('event_detail_modal',doc)

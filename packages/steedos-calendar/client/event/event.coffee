import 'fullcalendar/dist/fullcalendar.css'
import 'fullcalendar/dist/fullcalendar.js'

import 'fullcalendar/dist/locale-all.js'
import 'fullcalendar/dist/gcal.js'

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
	calendarIds = []
	if Meteor.isClient
		console.log !Session.get('calendarIds')
		if !Session.get('calendarIds')||Session.get('calendarIds')?.length==0
			objs = Calendars.find().fetch()
			objs.forEach (obj) ->
				calendarIds.push(obj._id)
			Session.set 'calendarIds',calendarIds
		else
			calendarIds=Session.get('calendarIds')
	
	params = 
		start: start.toDate()
		end: end.toDate()
		timezone: timezone
		calendar:calendarIds

	eventsSub.subscribe "calendar_objects", params

	Tracker.autorun (c)->
		if eventsSub.ready()
			events = Events.find(calendarid:{$in: params.calendar}).fetch()
			callback(events)
			c.stop()

Calendar.hasPermission = ( event )->
	obj = Events.findOne({'_id':event._id})
	if (obj.ownerId==Meteor.userId()&&obj.parentId==obj._id)
		return true
	else
		return false

Calendar.generateCalendar = ()->
	if !$('#calendar').children()?.length

		$('#calendar').fullCalendar
			height: ()->
				return $('#calendar').height()
			handleWindowResize: true
			header: 
				left: 'month,agendaWeek,agendaDay,listWeek',
				center: 'prev title next',
				right: ''
			selectable: true
			selectHelper: true
			# weekends:false
			navLinks: true
			editable: true
			eventLimit: true
			weekNumbers:false
			defaultView:'agendaWeek'
			events: Calendar.getEventsData
			timeFormat: 'H:mm'
			timezone: 'local'
			locale: Session.get('steedos-locale')
			noEventsMessage:t("no_events_message")
			buttonText:
				listWeek:t("calendar_list_week")
			# businessHours:
			# 	dow: [1,2,3,4,5],
			# 	start:'08:00',
			# 	end:'18:00'

			eventDataTransform: (event) ->
				copy =
					id: event._id
					allDay: event.allDay
					title: event.title
					url:event.url
					color:event.eventcolor
				if event.start
					copy.start = moment(event.start)
				if event.end
					copy.end = moment(event.end)
				return copy;
			select: (start, end, jsEvent, view, resource)->
				objs = Calendars.find()
				calendarid = ""
				objs.forEach (obj) ->
					if obj.isDefault
						# console.log obj._id
						calendarid = obj._id
				Session.set 'cmDoc', 
					start: start.toDate()
					end: end.toDate()
					calendarid:calendarid
				$('.btn.event-add').click(); 
			eventClick: (calEvent, jsEvent, view)->
				event = Events.findOne
					_id: calEvent.id
				if event
					Session.set 'cmDoc', event
					Modal.show('event_detail_modal')
			eventDrop: (event, delta, revertFunc)->
				hasPermission = Calendar.hasPermission(event)
				if !hasPermission
					swal(t("calendar_no_permission"),t("calnedar_no_permission_modify_event"),"warning");
					Calendar.reloadEvents()
					return
				Events.update({'_id':event._id},{
					$set:{
						'start':moment(event.start._d).toDate(),
						'end':moment(event.end._d).toDate()
					}
				})

			eventResize: (event, delta, revertFunc, jsEvent, ui, view)->
				hasPermission = Calendar.hasPermission(event)
				if !hasPermission
					swal(t("calendar_no_permission"),t("calnedar_no_permission_modify_event"),"warning");
					Calendar.reloadEvents()
					return
				Events.update({'_id':event._id},{
					$set:{
						'start':moment(event.start._d).toDate(),
						'end':moment(event.end._d).toDate()
					}
				})



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

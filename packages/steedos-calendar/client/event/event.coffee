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
	objs = Calendars.find()
	objs.forEach (obj) ->
		calendarIds.push(obj._id)
	console.log calendarIds

	params = 
		start: start.toDate()
		end: end.toDate()
		timezone: timezone
		calendar:calendarIds

	eventsLoading = true
	eventsSub.subscribe "calendar_objects", params

	Tracker.autorun (c)->
		if eventsSub.ready()
			events = Events.find().fetch()
			callback(events)
			c.stop()

Calendar.generateCalendar = ()->
	if !$('#calendar').children().length

		$('#calendar').fullCalendar
			height: ()->
				return $('#calendar').height()
			handleWindowResize: true
			header: 
				left: 'month,agendaWeek,agendaDay,listMonth',
				center: 'prev title next',
				right: ''
			selectable: true,
			selectHelper: true,
			navLinks: true
			editable: true
			eventLimit: true
			events: Calendar.getEventsData
			timeFormat: 'H(:mm)'
			# timezone: 'local'
			locale: Session.get("steedos-locale")
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
			select: ( start, end, jsEvent, view, resource )->
				# console.log ('start'+new Date(start)+'   end'+end)
				Session.set 'cmDoc', 
					start: start.toDate()
					end: end.toDate()
				$('.btn.event-add').click(); 
			eventClick: (calEvent, jsEvent, view)->
				event = Events.findOne
					_id: calEvent.id
				if event
					Session.set 'cmDoc', event
					Modal.show('event_detail_modal')
					# $('.btn.event-edit').click();
					# console.log ('start'+event.start+'   end'+event.end)


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

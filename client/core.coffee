
import moment from 'moment'

@Calendar = {}


eventsDep = new Tracker.Dependency;
eventsSub = new SubsManager();
eventsRange = null
eventsLoading = false

Calendar.reloadEvents = () ->
	eventsDep.depend()
	$("#calendar").fullCalendar("refetchEvents")


Calendar.getEventsData = ( start, end, timezone, callback )->
	
	params = 
		start: start.toDate()
		end: end.toDate()
		timezone: timezone

	eventsLoading = true
	eventsSub.subscribe "calendar_events", params

	Tracker.autorun (c)->
		if eventsSub.ready()
			events = Events.find().fetch();
			callback(events);
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
			eventDataTransform: (event) ->
				copy = 
					_id: event._id._str
					allDay: event.allDay
					url: event.url
					title: event.title
				if event.start
					copy.start = moment.utc(event.start)
				if event.end
					copy.end = moment.utc(event.end)
				return copy;
			select: ( start, end, jsEvent, view, resource )->
				Events.insert
					start: start.toDate()
					end: end.toDate()
					title: "New Event"
					allDay: false

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

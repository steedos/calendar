
import moment from 'moment'

@Calendar = {}


eventsDep = new Tracker.Dependency;

Calendar.reloadEvents = () ->
	eventsDep.depend();
	$("#calendar").fullCalendar("removeEvents");
	$("#calendar").fullCalendar("addEventSource", Calendar.getEventsData());
	$("#calendar").fullCalendar("refetchEvents");




Calendar.getEventsData = ()->
 
	events = Events.find().fetch();
	events = events.map (event) ->
		event.start = moment.utc(event.start);
		if event.end
			event.end = moment.utc(event.end);
		return event;

	return events;




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
			events: Calendar.getEventsData()

		Events.find().observeChanges 
			added: (id, event) ->
				eventsDep.changed();
			changed: () ->
				eventsDep.changed();
			removed: () ->
				eventsDep.changed();

		Calendar.eventsReloadHandle = Tracker.autorun ()->
			Calendar.reloadEvents();
	else
		Calendar.reloadEvents();

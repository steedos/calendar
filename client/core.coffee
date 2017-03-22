import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap/dist/js/bootstrap.js'

import 'admin-lte/dist/css/AdminLTE.css'
import 'admin-lte/dist/css/skins/skin-blue.css'
import 'admin-lte/dist/js/app.js'
import 'admin-lte/plugins/slimScroll/jquery.slimscroll.min.js'

import 'fullcalendar/dist/fullcalendar.css'
import 'fullcalendar/dist/fullcalendar.js'

import 'fullcalendar/dist/locale-all.js'
import 'fullcalendar/dist/gcal.js'

import moment from 'moment'

@Calendar = {}


eventsDep = new Tracker.Dependency;

Calendar.reloadEvents = () ->
	eventsDep.depend();
	$(".calendar-container").fullCalendar("removeEvents");
	$(".calendar-container").fullCalendar("addEventSource", Calendar.getEventsData());
	$(".calendar-container").fullCalendar("refetchEvents");




Calendar.getEventsData = ()->
 
	events = Events.find().fetch();
	events = events.map (event) ->
		event.start = moment.utc(event.start);
		if event.end
			event.end = moment.utc(event.end);
		return event;

	return events;




Meteor.startup ->

	$('.calendar-container').fullCalendar
		height: "parent" 
		header: 
			left: '',
			center: 'prev title next',
			right: 'month,agendaWeek,agendaDay,listMonth'
		navLinks: true
		editable: true
		eventLimit: true
		events: Calendar.getEventsData()

	Calendar.eventsReloadHandle = Tracker.autorun ()->
		Calendar.reloadEvents();
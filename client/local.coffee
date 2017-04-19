import 'moment/min/moment.min.js'
import 'jquery/dist/jquery.min.js'
import 'fullcalendar/dist/fullcalendar.js'
import 'fullcalendar/dist/locale-all.js'

Tracker.autorun ()->
	console.log ('locale1:'+Session.get("steedos-locale"))
	if Session.get("steedos-locale") == "zh-cn"
		if $('#calendar').children().length
			$('#calendar').fullCalendar('option', 'locale', 'zh-cn')
			console.log ('locale2:'+Session.get("steedos-locale"))
		else
			$('#calendar').fullCalendar('option', 'locale', 'en')

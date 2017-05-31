import 'moment/min/moment.min.js'
Tracker.autorun ()->
	if Session.get("steedos-locale") == "zh-cn"
		if $('#calendar').children().length
			$('#calendar').fullCalendar('option', 'locale', 'zh-cn')
		else
			$('#calendar').fullCalendar('option', 'locale', 'en')
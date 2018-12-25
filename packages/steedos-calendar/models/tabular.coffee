import moment from 'moment'
TabularTables.event_needs_action_tabular = new Tabular.Table({
	name: "event_needs_action_tabular",
	collection: Events,
	drawCallback:(settings)->
		box = $(this).closest(".event-pending-body")
		if !Steedos.isMobile() && !Steedos.isPad()
			$(box).perfectScrollbar()
	columns: [
		{
			data: "title", 
			orderable: false,
			width: "30%",
			search: {
				isNumber: true,
				exact: true,
			},
			render:  (val, type, doc) ->
				content = ""
				attendees = doc.attendees
				today = moment(moment().format("YYYY-MM-DD 00:00")).toDate()
				attendees.forEach (attendee,index) ->
					if attendee.id == Meteor.userId() and attendee.partstat == "NEEDS-ACTION" and doc.start >= today
						content = """
							<div class="ion ion-record need-action"></div>
						"""
				return """
					#{content}<div class="event-title">#{doc.title}</div>
				"""
		},
		{
			data: "attendees.invitetime",
			width: "8%",
			render: (val, type, doc) ->
				content = ""
				attendees = doc.attendees
				attendees.forEach (attendee,index) ->
					if attendee.id == Meteor.userId()
						content = moment(attendee.invitetime).format("M-DD HH:mm")
				return content
		},
		{
			data: "start",
			orderable: true,
			width: "8%",
			render:  (val, type, doc) ->
				if doc.allDay
					return moment(doc.start, Meteor.settings.public.calendar?.timezoneId).format("M-DD")
				else
					return moment(doc.start, Meteor.settings.public.calendar?.timezoneId).format("M-DD HH:mm")
				# console.log JSON.stringify(doc)
				# start = moment(doc.start).format("M-DD HH:mm")
				# end = moment(doc.end).format("M-DD HH:mm")
				# if doc.allDay
				# 	return "全天"
				# else
				# 	if start != end
				# 		return "#{start} - #{end}"
				# 	else
				# 		return "#{start}"
		},
		{
			data: "end",
			orderable: true,
			width: "8%",
			render:  (val, type, doc) ->
				if doc.allDay
					return moment(doc.end, Meteor.settings.public.calendar?.timezoneId).format("M-DD")
				else
					return moment(doc.end, Meteor.settings.public.calendar?.timezoneId).format("M-DD HH:mm")
		},
		{
			data: "attendees.inviter",
			orderable: false,
			width: "7%",
			render: (val, type, doc) ->
				content = ""
				attendees = doc.attendees
				attendees.forEach (attendee,index) ->
					if attendee.id == Meteor.userId()
						content = attendee.inviter
				return content
		},
		{
			data: "attendees.partstat",
			width: "5%",
			render:  (val, type, doc) ->
				content = ""
				attendees = doc.attendees
				attendees.forEach (attendee,index) ->
					if attendee.id == Meteor.userId()
						switch attendee.partstat
							when "ACCEPTED" then content = t("calendar_accepted")
							when "TENTATIVE" then content = t("calendar_tentative")
							when "DECLINED" then content = t("calendar_declined")
							when "NEEDS-ACTION" then content = t("calendar_needs_action")
				return content
							
						
			orderable: false
		},
		{
			data: "site",
			width: "12%",
			orderable: false
		},
		{
			data: "participation",
			width: "20%",
			orderable: false
		}
	],
	responsive: 
		details: false
	order: [[2,"desc"]]
	extraFields: ["end", "allDay", "alarms", "remintimes", "ownerId","attendees","calendarid","parentId","uid","uri","description"],
	lengthChange: false
	pageLength: 10
	info: false
	searching: true
	autoWidth: false
	changeSelector: (selector, userId) ->
		unless userId
			return {_id: -1}
		return selector
	pagingType: "numbers"
});
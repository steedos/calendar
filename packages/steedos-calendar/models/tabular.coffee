TabularTables.event_needs_action_tabular = new Tabular.Table({
	name: "event_needs_action_tabular",
	collection: Events,
	columns: [
		{
			data: "title", 
			orderable: false,
			search: {
				isNumber: true,
				exact: true,
			},
			render:  (val, type, doc) ->
				content = ""
				attendees = doc.attendees
				attendees.forEach (attendee,index) ->
					if attendee.id == Meteor.userId() and attendee.partstat == "NEEDS-ACTION"
						content = """
							<div class="ion ion-record need-action"></div>
						"""
				return """
					#{content}<div class="event-title">#{doc.title}</div>
				"""
		},
		{
			data: "site",
			orderable: false
		},
		{
			data: "participation",
			orderable: false
		},
		{
			data: "start",
			orderable: true,
			render:  (val, type, doc) ->
				return moment(doc.start).format("M-DD HH:mm")
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
			render:  (val, type, doc) ->
				return moment(doc.end).format("M-DD HH:mm")
		}
	],
	order: [[3,"desc"]]
	extraFields: ["end", "allDay", "alarms", "remintimes", "ownerId","attendees","calendarid"],
	lengthChange: false
	pageLength: 10
	info: false
	searching: true
	autoWidth: false
	# responsive: 
	# 	details: false
	changeSelector: (selector, userId) ->
		unless userId
			return {_id: -1}
		return selector
	pagingType: "numbers"
});
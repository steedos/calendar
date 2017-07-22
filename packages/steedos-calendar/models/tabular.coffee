TabularTables.event_needs_action_tabular = new Tabular.Table({
	name: "event_needs_action_tabular",
	collection: Events,
	columns: [
		{
			data: "title", 
			
		},
		{
			data: "site",
		},
		{
			data: "participation",
		},
		{
			data: "start"
			render:  (val, type, doc) ->
				console.log JSON.stringify(doc)
				start = moment(doc.start).format("M-DD HH:mm")
				end = moment(doc.end).format("M-DD HH:mm")
				if doc.allDay
					return "全天"
				else
					if start != end
						return "#{start} - #{end}"
					else
						return "#{start}"
		}
	],
	dom: "tp",
	order:[[0,"desc"]],
	extraFields: ["end", "allDay", "alarms", "remintimes", "ownerId","attendees","calendarid"],
	lengthChange: false,
	pageLength: 10,
	info: false,
	responsive: 
		details: false
	autoWidth: false,
	changeSelector: (selector, userId) ->
		unless userId
			return {_id: -1}
		return selector
	pagingType: "numbers"
});
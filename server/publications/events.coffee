Meteor.publish "calendar_events", (params)->
	selector =
		$or: [
			end: {$gt: params.start},
			start: {$lt: params.end}
		]

	return Events.find(selector);
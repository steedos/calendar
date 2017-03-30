Meteor.publish "calendar_events", (params)->
	selector =
		$or: [
			end: {$gt: params.start},
			start: {$lt: params.end},
			calendar:{$in: params.calendar}
		]

	return Events.find(selector);
Meteor.publish "calendar_objects", (params)->
	selector =
		calendarid:{$in: params.calendar},
		start:{ $exists: true },
		$or:[
			start: {$lte: params.end},
			end: {$gte: params.start}
		]
	return Events.find(selector)
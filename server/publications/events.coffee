Meteor.publish "calendar_objects", (params)->
	selector =
		$or: [
			end: {$gt: params.start},
			start: {$lt: params.end},
			calendarid:{$in: params.calendar}
		]

	return Events.find()
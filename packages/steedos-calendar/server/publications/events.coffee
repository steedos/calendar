Meteor.publish "calendar_objects", (params)->
	selector =
		calendarid:{$in: params.calendar},
		start:{ $exists: true },
		$or:[
			start: {$lte: params.end},
			end: {$gte: params.start}
		]
	return Events.find selector,
		fields:
				_id:1,
				calendarid:1,
				ownerId:1,
				attendees:1
				start:1
				end:1,
				title:1,
				site:1,
				allDay:1,
				alarms:1,
				parentId:1,
				remindtimes:1
Meteor.publish "event-need-action",(calendarid) ->
	today = moment(moment().format("YYYY-MM-DD 00:00")).toDate()
	endLine = moment().toDate()
	selector = 
			{
				calendarid: calendarid,
				start: {$gte:today},
				end: {$gte: endLine},
				"attendees": {
					$elemMatch: {
						partstat: "NEEDS-ACTION"
					}
				}
			}
	return Events.find selector,
		fields:	
				calendarid:1,
				start:1,
				end:1,
				attendees:1,
				alarms:1
				
				
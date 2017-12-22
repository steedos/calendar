Meteor.methods
	alarmPush: (syntime) ->
		events = Events.find({end:{$gte:new Date()},remindtimes:{$elemMatch:{$gte:syntime, $lt:syntime+60*1000}}}).fetch()		
		events.forEach (event)->
				if event.parentId == event._id
					event.attendees?.forEach (attendee)->
							if attendee.partstat!='DECLINED' 
								Meteor.call('eventNotification',event,attendee.id,4)

Meteor.startup ->
		Calendar.SendMessageTimeout = (time)->
				currenttime=moment()._d.getTime()
				Meteor.setTimeout(()->
					Meteor.call('alarmPush',currenttime)
					currenttime = currenttime+60*1000
					Calendar.SendMessageTimeout(time)
				,time)

		Calendar.SendMessageTimeout Meteor.settings.cron.calendar_remind

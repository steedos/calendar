Meteor.methods
	alarmPush: (syntime) ->
		events = Events.find({end:{$gte:new Date()},remindtimes:{$elemMatch:{$gte:syntime, $lt:syntime+60*1000}}}).fetch()
		if events
			events.forEach (event)->
				if event.attendees
					event.attendees.forEach (attendee)->
						if attendee.partstat=='ACCEPTED'
							payload = 
								app: 'workflow'
								id: attendee.id
							start = moment(event.start).format("YYYY-MM-DD HH:mm")
							site = event.site || ""
							title = "您的会议#{event.title}"
							if site
								text = "会议时间:#{start}\r会议地点:#{site}"
							else
								text = "会议时间:#{start}"
							#text = "会议时间:#{start}\r会议地点:#{site}"
							Push.send
								createdAt: new Date()
								createdBy: '<SERVER>'
								from: 'workflow',
								title: title,
								text: text,
								payload: payload
								badge: 12
								query: {userId:attendee.id,appName:"workflow"}

Meteor.startup ->
	Calendar.SendMessageTimeout = (time)->
			currenttime=moment()._d.getTime()
			Meteor.setTimeout(()->
				
				Meteor.call('alarmPush',currenttime)
				currenttime = currenttime+60*1000
				Calendar.SendMessageTimeout(time)
			,time)

	Calendar.SendMessageTimeout 60*1000

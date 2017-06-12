JsonRoutes.add "get", "/api/calendar/events", (req, res, next) ->
	user_id = req.headers['x-user-id']

	auth_token = req.headers['x-auth-token']

	space_id = req.headers['x-space-id']

	if !user_id
			JsonRoutes.sendResult res,
				code: 401,
				data:
					"error":"Validate Request -- Missing X-Auth-Token,X-User-Id",
					"success":false
			return;

	userCalendar = Calendars.find({ownerId:user_id}).map (obj) ->
		return obj._id
	userEvent = []
	userCalendar.forEach (id) ->
		Events.find({calendarid:id},{sort:{start:-1},limit:5},{fields:{title:1,start:1,end:1}}).fetch().forEach (obj) ->
			obj.start = moment(obj.start).format("YYYY-MM-DD HH:mm")
			obj.end = moment(obj.end).format("YYYY-MM-DD HH:mm")
			userEvent.push obj


	JsonRoutes.sendResult res,
		code: 200,
		data:
			"status":"success",
			"data":userEvent
	return;
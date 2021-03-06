import moment from 'moment'
JsonRoutes.add "get", "/api/calendar/events", (req, res, next) ->
	
	space_id = req.headers['x-space-id'] || req.query?.spaceId

	user = Steedos.getAPILoginUser(req, res)

	if !user
			JsonRoutes.sendResult res,
				code: 401,
				data:
					"error":"Validate Request -- Missing X-Auth-Token,X-User-Id",
					"success":false
			return;

	user_id = user._id

	start = moment().format("YYYY-MM-DD 00:00")
	utcOffsetHours = db.users.findOne(user_id).utcOffset
	start = moment(start).subtract(utcOffsetHours,"hours").toDate()
	calendarid = Calendars.findOne({ownerId:user_id,isDefault:true})?._id
	if calendarid
		userEvent = Events.find({
			calendarid:calendarid,
			start: {$gt: start}},{sort:{start:-1}
		},limit:20).fetch() || []
	else
		userEvent = []
	


	JsonRoutes.sendResult res,
		code: 200,
		data:
			"status":"success",
			"data":userEvent
	return;
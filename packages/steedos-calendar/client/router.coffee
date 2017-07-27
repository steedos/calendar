checkUserSigned = (context, redirect) ->
	if !Meteor.userId()
		FlowRouter.go '/steedos/sign-in?redirect=' + context.path;

checkUserInbox = () ->
	userId = Meteor.userId()
	Tracker.autorun (c) ->
		calendarid = Session.get("defaultcalendarid")
		if calendarid
			selector = 
			{
				calendarid: calendarid,
				"attendees": {
					$elemMatch: {
						id: userId,
						partstat: "NEEDS-ACTION"
					}
				}
			}
			if Events.find(selector).count()
				FlowRouter.go '/inbox'

FlowRouter.route '/',
	triggersEnter: [ checkUserSigned,checkUserInbox ],
	action: (params, queryParams)->
		BlazeLayout.render 'calendarLayout',
			main: "calendarContainer"

FlowRouter.route '/inbox',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		BlazeLayout.render 'calendarLayout',
			main: "eventPending"

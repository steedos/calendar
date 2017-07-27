checkUserSigned = (context, redirect) ->
	if !Meteor.userId()
		FlowRouter.go '/steedos/sign-in?redirect=' + context.path;

checkUserInbox = () ->
	userId = Meteor.userId()
	Tracker.autorun (c) ->
		calendarid = Session.get("defaultcalendarid")
		if calendarid and calendarsSub.ready()
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
				toastr.info t("you_have_invitation_to_feedback_please_fill_in_the_invitation")
			c.stop()

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

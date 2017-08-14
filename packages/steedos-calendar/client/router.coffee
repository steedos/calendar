checkUserSigned = (context, redirect) ->
	if !Meteor.userId()
		FlowRouter.go '/steedos/sign-in?redirect=' + context.path;

FlowRouter.route '/calendar',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		BlazeLayout.render 'calendarLayout',
			main: "calendarContainer"

FlowRouter.route '/calendar/inbox',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		BlazeLayout.render 'calendarLayout',
			main: "eventPending"

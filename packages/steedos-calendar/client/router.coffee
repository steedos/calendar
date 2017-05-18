checkUserSigned = (context, redirect) ->
	if !Meteor.userId()
		FlowRouter.go '/steedos/sign-in?redirect=' + context.path;


calendarRoutes = FlowRouter.group
	triggersEnter: [ checkUserSigned ],
	prefix: '/calendar',
	name: 'calendar'

calendarRoutes.route '/',
	action: (params, queryParams)->
		BlazeLayout.render 'calendarLayout',
			main: "calendarContainer"

calendarRoutes.route '/event/:_id',
	action: (params, queryParams)->
		BlazeLayout.render 'calendarLayout',
			main: "eventDetail"


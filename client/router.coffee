FlowRouter.route '/',
	action: (params, queryParams)->
		if !Meteor.userId()
			FlowRouter.go '/steedos/sign-in';
		else
			FlowRouter.go '/calendar'

Meteor.startup ->
	if Meteor.isClient
		Session.set("apps",["calendar"])
		db.apps.INTERNAL_APPS = []
		Tracker.autorun ()->
			Steedos.Helpers.setAppTitle(t "Steedos Calendar");

		$("body").removeClass("skin-blue").addClass("skin-blue-light")

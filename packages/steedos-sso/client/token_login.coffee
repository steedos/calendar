checkAndLogin = (context)->
	if Accounts._storedUserId()
		if context?.queryParams?["X-User-Id"] && Meteor?.userId() != context?.queryParams?["X-User-Id"]
			console.log "logout : #{Meteor.userId()}"
			SteedosSSO.login(context)
	else
		console.log "checkAndLogin else"
		SteedosSSO.login(context)


FlowRouter.triggers.enter([checkAndLogin]);
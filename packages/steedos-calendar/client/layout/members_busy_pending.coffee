Template.members_busy_pending_modal.onCreated ->
	this.reactiveCounts = new ReactiveVar(0)

Template.members_busy_pending_modal.onRendered ->
	$("#busyPending_modal .modal-body").css("max-height",Steedos.getModalMaxHeight())

Template.members_busy_pending_modal.helpers
	members: ()->
		defaultCalendarId = Session.get "defaultcalendarid"
		members = Calendars.findOne({_id:defaultCalendarId}).members_busy_pending || []
		return members

	isButtonDisabled: ()->
		# debugger
		count = Template.instance().reactiveCounts.get()
		if count > 0 
			return false
		else
			return true

Template.members_busy_pending_modal.events
	'click .btn-accept':(event) ->
		# memberId = this._id
		memberIds = []
		checkbox =  $("input[name='member']:checked")
		checkbox.each () ->
			memberIds.push(this.value)
		Meteor.call("updateMembersBusy",memberIds,"accept",
			(error,result)->
				if error
					console.log error
				else
					defaultCalendarId = Session.get "defaultcalendarid"
					members = Calendars.findOne({_id:defaultCalendarId})?.members_busy_pending
					if !members or !members.length
						$('[data-dismiss="modal"]').click()
		)
		$('input[name=checkAll]').removeAttr("checked")


	'click .btn-refuse':(event) ->
		memberIds = []
		checkbox =  $("input[name='member']:checked")
		checkbox.each () ->
			memberIds.push(this.value)
		Meteor.call("updateMembersBusy",memberIds,"refuse",
			(error,result)->
				if error
					console.log error
				else	
					defaultCalendarId = Session.get "defaultcalendarid"
					members = Calendars.findOne({_id:defaultCalendarId})?.members_busy_pending
					if !members or !members.length
						$('[data-dismiss="modal"]').click()
		)
		$('input[name=checkAll]').removeAttr("checked")

	'change input[name=checkAll]':(event,template) ->
		if $('input[name=checkAll]').is(":checked")
			$('input[name=member]').prop("checked",true)
		else
			$('input[name=member]').removeAttr("checked")
		template.reactiveCounts.set($("input[name='member']:checked").length)

	'change input[name=member]':(event,template) ->
		template.reactiveCounts.set($("input[name='member']:checked").length)

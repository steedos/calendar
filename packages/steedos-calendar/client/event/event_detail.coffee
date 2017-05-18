
Template.event_detail_modal.onRendered ->
	

Template.event_detail_modal.helpers
	eventObj:()->
		obj = Session.get('cmDoc')
		return obj

	members:()->
		obj = Session.get('cmDoc')

		return selectGetUsers obj.members

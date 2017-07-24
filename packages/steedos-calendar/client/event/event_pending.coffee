Template.eventPending.onCreated ->

Template.eventPending.onRendered ->

Template.eventPending.helpers
	EventListSelector :()->
		calendarid = Session.get "defaultcalendarid"
		userId = Meteor.userId();
		if calendarid
			query = 
				{
					calendarid: calendarid,
					"attendees": {
						$elemMatch: {
							id: userId,
						}
					}
				}
			return query

	calendarSubsReady: ()->
		defaultcalendarid = Session.get "defaultcalendarid"
		return defaultcalendarid

Template.eventPending.events
	'click tbody > tr': (event)->
		Session.set "userOption","click"
		dataTable = $(event.target).closest('table').DataTable();
		rowData = dataTable.row(event.currentTarget).data();
		Modal.show('event_detail_modal',rowData)
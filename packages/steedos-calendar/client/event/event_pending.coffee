Template.eventPending.onCreated ->

Template.eventPending.helpers
	EventListSelector :()->
		calendarid = Session.get "defaultcalendarid"
		userId = Meteor.userId();
		query = 
			{
				calendarid: calendarid,
				"attendees": {
					$elemMatch: {
						id: userId,
						partstat: "NEEDS-ACTION"
					}
				}
			}
		console.log JSON.stringify(query) 
		return query

Template.eventPending.events
	'click tbody > tr': (event)->
    	dataTable = $(event.target).closest('table').DataTable();
    	rowData = dataTable.row(event.currentTarget).data();
    	Modal.show('event_detail_modal',rowData)
    	console.log rowData
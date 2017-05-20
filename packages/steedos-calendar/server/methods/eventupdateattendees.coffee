Meteor.methods
	eventupdateattendees: (parentId,action) ->
		events=Events.find({parentId:parentId},{fields:{attendees:1}}).fetch()
		console.log events
		events.forEach (event)->
		 	attendees=event.attendees
		 	attendees.forEach (attendee)->
			 	if attendee.id==Meteor.userId()
			 		attendee.partstat=action
	 		Events.update({_id:event._id},{$set:{attendees:attendees}})
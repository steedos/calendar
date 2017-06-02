Meteor.methods
	eventInit: (userId,doc) ->
		doc.componenttype = "VEVENT"
		doc._id = Calendar.uuid();
		doc.uid = doc._id	
		doc.uri = doc._id + ".ics"
		doc.ownerId=userId;
		if _.indexOf(doc.members, userId)==-1
			doc.members.push userId
		attendees=[]
		doc.members.forEach (member)->
			partstat="NEEDS-ACTION"
			steedosId=Meteor.users.findOne({_id:member}).steedos_id
			name=Meteor.users.findOne({_id:member}).name
			attendee = {
				role:"REQ-PARTICIPANT",
				cutype:"INDIVIDUAL",
				partstat:partstat,
				cn:name,
				mailto:steedosId,
				id:member,
				description:null
			}
			if member == doc.ownerId 
				attendee.partstat="ACCEPTED"
			attendees.push attendee  	
		doc.attendees = attendees;
		Calendar.addCalendarObjects(userId,doc,1);
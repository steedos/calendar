Meteor.methods
	eventInit: (userId,doc) ->
		doc.componenttype = "VEVENT"
		doc._id = Calendar.uuid()
		doc.uid = doc._id	
		doc.uri = doc._id + ".ics"
		doc.ownerId=userId
		attendees=[]
		attendee = {
			role:"REQ-PARTICIPANT",
			cutype:"INDIVIDUAL",
			partstat:"ACCEPTED",
			cn:Meteor.users.findOne({_id:userId}).name,
			mailto:Meteor.users.findOne({_id:userId}).steedos_id,
			id:userId,
			description:null
		}
		attendees.push attendee  	
		doc?.attendees = attendees
		doc1 = Calendar.addCalendarObjects(userId,doc,1)
		Events.insert(doc1,(error,result)->
				if !error
					console.log result
					return result
				else
					console.log error
					return
			)
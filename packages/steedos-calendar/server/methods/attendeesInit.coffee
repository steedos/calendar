Meteor.methods
	attendeesInit :(obj,attendeeid)->
		partstat="NEEDS-ACTION"
		steedosId=Meteor.users.findOne({_id:attendeeid}).steedos_id
		name=Meteor.users.findOne({_id:attendeeid}).name
		attendee = {
			role:"REQ-PARTICIPANT",
			cutype:"INDIVIDUAL",
			partstat:partstat,
			cn:name,
			mailto:steedosId,
			id:attendeeid,
			description:null
		}
		if attendeeid == obj.ownerId 
			attendee.partstat="ACCEPTED"  
		obj.attendees.push attendee
		return obj
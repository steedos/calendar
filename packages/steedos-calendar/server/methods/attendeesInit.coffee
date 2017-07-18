Meteor.methods
	attendeesInit :(obj,addmembers)->
		if obj?.attendees
			attendeesid=_.pluck(obj.attendees,'id');
		else
			attendeesid = []
			obj.attendees = []
		addmembers.forEach (addmember)->
			if _.indexOf(attendeesid, addmember)==-1
				partstat="NEEDS-ACTION"
				steedosId=Meteor.users.findOne({_id:addmember}).steedos_id
				name=Meteor.users.findOne({_id:addmember}).name
				attendee = {
					role:"REQ-PARTICIPANT",
					cutype:"INDIVIDUAL",
					partstat:partstat,
					cn:name,
					mailto:steedosId,
					id:addmember,
					description:null
				}
				if addmember == obj.ownerId 
					attendee.partstat="ACCEPTED"  
				obj.attendees.push attendee
		return obj
Meteor.methods
	attendeesInit :(obj,addmembers)->
		if obj?.attendees
			attendeesid=_.pluck(obj.attendees,'id');
		else
			attendeesid = []
			obj.attendees = []
		inviter = db.users.findOne({_id:this.userId})?.name
		addmembers.forEach (addmember)->
			if _.indexOf(attendeesid, addmember)==-1
				partstat="NEEDS-ACTION"
				steedosId=Meteor.users.findOne({_id:addmember},{field:{steedos_id:1}})?.email
				name=Meteor.users.findOne({_id:addmember}).name
				attendee = {
					role:"REQ-PARTICIPANT",
					cutype:"INDIVIDUAL",
					partstat:partstat,
					cn:name,
					mailto:steedosId,
					id:addmember,
					inviter:inviter,
					invitetime:new Date(),
					description:null
				}
				if addmember == obj.ownerId 
					attendee.partstat="ACCEPTED"  
				obj.attendees.push attendee
		return obj
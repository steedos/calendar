Meteor.methods
	calendarinsert: (doc) ->
		console.log "====instance"
		if doc.ownerId==undefined
			doc.ownerId=Meteor.userId()
		ownerId = doc.ownerId
		console.log doc
		doc._id=Calendars.direct.insert(doc)
		steedosId = Meteor.users.findOne({_id:ownerId}).steedos_id;
		Calendar.addInstance(ownerId,doc,doc._id,steedosId,1,"","");
		for member,i in doc.members 
			if member != ownerId
				steedosId = Meteor.users.findOne({_id:member})?.steedos_id;
				herf="mailto:" + steedosId;
				displayname=steedosId;
				Calendar.addInstance(ownerId,doc,doc._id,steedosId,2,herf,displayname);	
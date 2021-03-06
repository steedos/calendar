import { Calendar } from '../main';
Meteor.methods
	calendarinsert: (doc) ->
		if doc.ownerId==undefined
			doc.ownerId=Meteor.userId()
		ownerId = doc.ownerId
		doc._id=Calendars.direct.insert(doc)
		steedosId = Meteor.users.findOne({_id:ownerId},{field:{steedos_id:1}})?.email;
		if !steedosId
			steedosId = ownerId
		Calendar.addInstance(ownerId,doc,doc._id,steedosId,1,"","");
		if doc.members
			for member,i in doc.members 
				if member != ownerId
					steedosId = Meteor.users.findOne({_id:member},{field:{steedos_id:1}})?.email;
					if !steedosId
						steedosId = member
					herf="mailto:" + steedosId;
					displayname=steedosId;
					Calendar.addInstance(member,doc,doc._id,steedosId,2,herf,displayname);
		return doc

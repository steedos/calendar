import { Meteor } from 'meteor/meteor';

Meteor.startup ->
	
@Calendar = 
	addChange : (calendarId,startToken,tokenCount, objectUri, operation)->
		#oldsynctoken = Calendars.findOne({_id:calendarId}).synctoken;
		i = 1
		while i <= tokenCount
			calendarchanges.insert
				uri:objectUri,
				synctoken: startToken+i,
				calendarid: calendarId,
				operation: operation
			i++		
		Calendars.direct.update({_id:calendarId},{$set:{synctoken:startToken+tokenCount}});
	
	addInstance : (userId,doc,steedosId,herf,displayname)->
		if doc.visibility == 'private'
			transp = false;
		else
			transp = true;
		console.log  "calendarinstances"
		calendarinstances.insert
			principaluri:"principals/" + steedosId,
			uri:doc.title + doc._id,
			transparent:transp,
			access:2,
			share_invitestatus:4,
			calendarid: doc._id,
			displayname:doc.title,
			description:"null",
			timezone:"Shanghai",
			calendarorder:3,
			calendarcolor: doc.color,
			share_herf:herf,
			share_displayname: displayname

		
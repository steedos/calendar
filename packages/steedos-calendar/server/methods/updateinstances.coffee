Meteor.methods
	updateinstances :(calendarid,userId,checked)->
		calendarinstances.direct.update({calendarid:calendarid,principalid:userId},{$set: {checked:checked}})
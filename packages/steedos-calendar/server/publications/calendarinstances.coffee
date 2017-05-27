Meteor.publish "calendarinstances", (params)->
	return calendarinstances.find({checked:true,principalid:params});
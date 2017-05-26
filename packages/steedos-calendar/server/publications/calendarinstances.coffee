Meteor.publish "calendar_instances", (params)->
	
	unless this.userId
		return this.ready();
	return Calendarinstances.find({$or:[{"ownerId":this.userId},{"members":this.userId}]});
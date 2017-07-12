Meteor.publish "calendars", (params)->
	
	unless this.userId
		return this.ready();
	return Calendars.find({$or:[{"ownerId":this.userId},{"members":this.userId},{"members_readonly":this.userId}]});

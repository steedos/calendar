
Meteor.publish "calendars", (params)->
	
	return Calendars.find();

# Meteor.publish "calendars", (params)->
	
# 	return Calendars.remove("_id",params._id);
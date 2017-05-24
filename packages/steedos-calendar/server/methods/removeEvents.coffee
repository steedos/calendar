Meteor.methods
	removeEvents :(obj)->
		Events.direct.remove({_id:obj._id})
		Calendar.addChange(obj.calendarid,obj.uri,3);
		if obj.parentId==obj._id
			attendeesid=_.pluck(obj.attendees,'id');
			attendeesid.forEach (attendeeid)->
				calendarid=Calendars.findOne({ownerId:attendeeid},{isDefault:true})._id
				event=Events.find({parentId:obj._id,calendarid:calendarid},{fields:{uri:1}}).fetch()
				if event.length!=0
					Events.direct.remove({parentId:obj._id,calendarid:calendarid})
					Calendar.addChange(calendarid,event[0].uri,3);
		
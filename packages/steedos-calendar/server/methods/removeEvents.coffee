import { Calendar } from '../main';
Meteor.methods
	removeEvents :(obj)->
		Events.direct.remove({_id:obj._id})
		Calendar.addChange(obj.calendarid,obj.uri,3);
		if obj.attendees
			if obj.ownerId==Meteor.userId()
				attendeesid=_.pluck(obj.attendees,'id');
				currenttime = new Date()
				attendeesid.forEach (attendeeid)->
					if obj.attendees[attendeesid.indexOf(attendeeid)].partstat == 'ACCEPTED' and obj.end - currenttime>0						
						Meteor.call('eventNotification',obj,attendeeid,3)
					calendarid=Calendars.findOne({ownerId:attendeeid,isDefault:true})._id
					event=Events.find({parentId:obj._id,calendarid:calendarid},{fields:{uri:1}}).fetch()
					if event.length!=0
						Events.direct.remove({parentId:obj._id,calendarid:calendarid})
						Calendar.addChange(calendarid,event[0].uri,3);
			attendeesid=_.pluck(obj.attendees,'id');
			dx=attendeesid.indexOf(Meteor.userId())
			if dx>-1
				obj.attendees[dx].partstat="DECLINED"
			Events.direct.update {parentId:obj.parentId},{$set:
				attendees:obj.attendees},{ multi: true }

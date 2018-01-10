import moment from 'moment'
Meteor.publish "reminders", (params)->
	defaultcalendar=Calendars.findOne({ownerId:this.userId,isDefault:true}, {fields:{_id: 1,color:1}})
	return Events.find({calendarid:defaultcalendar?._id,start: {$gte: moment().toDate()}})
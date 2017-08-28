import { Calendar } from '../main';
Meteor.methods
	subCalendar: (calendarObj,option)->
		subCalendar = calendarsubscriptions.find({uri:calendarObj._id,principaluri:this.userId})?.fetch()
		if option == "sub"
			if subCalendar.length > 0
				calendarsubscriptions.remove({_id:subCalendar[0]?._id})
				subCalendar[0].uri
			else
				calendarsubscriptions.direct.insert
					_id: Calendar.uuid()
					uri: calendarObj._id
					principaluri: this.userId
					color: calendarObj.color
					calendarname: calendarObj.title
		else if option == "check"
			if subCalendar.length == 0
				calendarsubscriptions.direct.insert
					_id: Calendar.uuid()
					uri: calendarObj._id
					principaluri: this.userId
					color: calendarObj.color
					calendarname: calendarObj.title
			return calendarObj._id
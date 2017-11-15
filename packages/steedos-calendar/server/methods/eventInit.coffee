import { Calendar } from '../main';
import moment from 'moment'
Meteor.methods
	eventInit: (userId,doc) ->
		doc.componenttype = "VEVENT"
		doc._id = Calendar.uuid()
		doc.uid = doc._id	
		doc.uri = doc._id + ".ics"
		doc.Isdavmodified = false
		doc = Calendar.addCalendarObjects(userId,doc,1)
		isDefaultCalendar=Calendars.findOne({_id:doc.calendarid}).isDefault
		if isDefaultCalendar
			addMembers=[]
			addMembers.push userId
			doc = Meteor.call('attendeesInit',doc,addMembers)
		Events.insert(doc,(error,result)->
				if !error
					return result
				else
					console.log error
					return
			)
		attendeesid=_.pluck(doc.attendees,'id')
		dx=attendeesid.indexOf(userId)
		# isDefaultCalendar=Calendars.findOne({ownerId:userId},{_id:doc.calendarid}).isDefault
		# if !isDefaultCalendar and dx<0 and attendeesid.length==0
		#  	attendeesid.push(userId)
		attendeesid.forEach (attendeeid)->
				calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})				
				if calendar==undefined
					Meteor.call('calendarInit',attendeeid,Defaulttimezone);
					calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})			
				if  doc.calendarid!=calendar?._id
					_id = Calendar.uuid()
		#calendar=Calendars.findOne({ownerId:userId},{isDefault:true}, {fields:{_id: 1,color:1}})
		#if calendar._id !=doc.calendarid
			#_id = Calendar.uuid()
					obj = {
						_id:_id;
						title:doc.title
						start:doc.start
						end:doc.end
						allDay:doc.allDay
						calendarid:calendar._id
						site:doc.site
						participation:doc.participation
						description:doc.description
						alarms:doc.alarms
						componenttype:doc.componenttype
						uid:_id
						uri:_id+".ics"
						ownerId:doc.ownerId
						lastmodified:doc.lastmodified
						Isdavmodified:false
						firstoccurence:doc.firstoccurence
						lastoccurence:doc.lastoccurence
						attendees:doc.attendees
						calendardata:doc.calendardata
						etag:doc.etag
						size:doc.size
						eventcolor:calendar.color
						parentId:doc.parentId
					}
					Events.direct.insert obj
					Calendar.addChange(calendar._id,_id+".ics",1);
				else
					Calendar.addChange(doc.calendarid,doc.uri,1);
				currenttime = new Date()
				if currenttime- doc.end<0
					payload = 
						app: 'workflow'
						id: attendeeid
					start = moment(doc.start).format("YYYY-MM-DD HH:mm")
					site = doc.site || ""
					title = "您有新的会议邀请#{doc.title}"
					if site
						text = "会议时间:#{start}\r会议地点:#{site}"
					else
						text = "会议时间:#{start}"
					Push.send
						createdAt: new Date()
						createdBy: '<SERVER>'
						from: 'workflow',
						title: title,
						text: text, 
						payload: payload
						badge: 12
						query: {userId:attendeeid,appName:"workflow"}
					userPush = []
					userPush = Push.appCollection.find({userId:attendeeid,appName:"workflow"}).fetch()
					if userPush.length==0
						user = db.users.findOne({_id:attendeeid}, {fields: {mobile: 1, utcOffset: 1, locale: 1, name: 1}})
						lang = 'en'
						start = moment(doc.start).format("YYYY-MM-DD HH:mm")
						if user.locale is 'zh-cn'
							lang = 'zh-CN'
						# 发送手机短信
						if doc.alarms.indexOf("Now")>=0
							SMSQueue.send
								Format: 'JSON',
								Action: 'SingleSendSms',
								ParamString: '',
								RecNum: user.mobile,
								SignName: '华炎办公',
								TemplateCode: 'SMS_67200967',
								msg: TAPi18n.__('sms.calendar_event.template', {event_action: "会议邀请",event_title:doc.title, event_time:start, event_location: doc.site}, lang)
				
		return doc
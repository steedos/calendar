import { Calendar } from '../main';
import moment from 'moment'
Meteor.methods
	updateEvents :(obj,operation,relatetodefaultcalendar,oldcalendarid)->
		if operation==1
			attendees=[]
		else
			events=Events.find({_id:obj._id}).fetch()
			attendees=events[0].attendees	
		if obj._id==obj.parentId || obj.Isdavmodified
			currenttime = new Date()
			newattendeesid=_.pluck(obj?.attendees,'id');
			if attendees
				oldattendeesid=_.pluck(attendees,'id');
			else
				oldattendeesid=[]
			subattendeesid=_.difference oldattendeesid,newattendeesid;
			addattendeesid=_.difference newattendeesid,oldattendeesid;
			updateattendeesid=_.difference newattendeesid,addattendeesid
			if obj.Isdavmodified
				updateattendeesid.push obj.ownerId
			#被去掉的attendees的对应event需要删除
			if relatetodefaultcalendar=='No'
				addattendeesid.push Meteor.userId()
			if relatetodefaultcalendar=='Yes'
				subattendeesid.push Meteor.userId()
				Calendar.addChange(oldcalendarid,obj.uri,3);
				#if obj.Isdavmodified==true

			subattendeesid.forEach (attendeeid)->				
				calendarid=Calendars.findOne({ownerId:attendeeid,isDefault:true})._id
				event=Events.find({parentId:obj._id,calendarid:calendarid},{fields:{uri:1}}).fetch()
				Events.direct.remove({parentId:obj._id,calendarid:calendarid})
				Calendar.addChange(calendarid,event[0]?.uri,3);
				if events[0].attendees[oldattendeesid.indexOf(attendeeid)].partstat=='ACCEPTED' and obj.end - currenttime>0
					payload = 
						app: 'workflow'
						id: attendeeid
					start = moment(obj.start).format("YYYY-MM-DD HH:mm")
					site = obj.site || ""
					title = "您的会议邀请#{obj.title}已取消"
					if site
						text = "会议时间:#{start}\r会议地点:#{site}"
					else
						text = "会议时间:#{start}"
					#text = "会议时间:#{start}\r会议地点:#{site}"
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
						if user.locale is 'zh-cn'
							lang = 'zh-CN'
						# 发送手机短信
						if obj.alarms.indexOf("Now")>=0
							SMSQueue.send
								Format: 'JSON',
								Action: 'SingleSendSms',
								ParamString: '',
								RecNum: user.mobile,
								SignName: '华炎办公',
								TemplateCode: 'SMS_67200967',
								msg: TAPi18n.__('sms.calendar_event.template', {event_action: "会议取消",event_title:obj.title, event_time:start, event_location:obj.site}, lang)
			#新加的attendees需要新建event
			doc=Calendar.addCalendarObjects(obj.ownerId,obj,operation);	
			addattendeesid.forEach (attendeeid)->
				calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})				
				if calendar==undefined
					Meteor.call('calendarInit',attendeeid,Defaulttimezone);
					calendar=Calendars.findOne({ownerId:attendeeid,isDefault:true}, {fields:{_id: 1,color:1}})			
				if  doc.calendarid!=calendar?._id
					_id = Calendar.uuid()
					Events.direct.insert
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
						remindtimes: doc.remindtimes
						componenttype:doc.componenttype
						uid:_id
						uri:_id+".ics"
						ownerId:doc.ownerId
						lastmodified:doc.lastmodified
						firstoccurence:doc.firstoccurence
						lastoccurence:doc.lastoccurence
						attendees:doc.attendees
						calendardata:doc.calendardata
						etag:doc.etag
						size:doc.size
						Isdavmodified:false
						parentId:doc.parentId
					Calendar.addChange(calendar._id,_id+".ics",2);
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
					#text = "会议时间:#{start}\r会议地点:#{site}"
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
								msg: TAPi18n.__('sms.calendar_event.template', {event_action: "会议邀请",event_title:doc.title, event_time:doc.start, event_location: doc.site}, lang)
			updateattendeesid.forEach (attendeeid)->
				if attendeeid==obj.ownerId and obj._id==obj.parentId
					Events.direct.update {_id:obj._id}, {$set: 
						calendarid:doc.calendarid}
					#Calendar.addChange(doc.calendarid,doc.uri,2)
				if currenttime- doc.end<0
					payload = 
						app: 'workflow'
						id: attendeeid
					start = moment(doc.start).format("YYYY-MM-DD HH:mm")
					site = doc.site || ""
					title = "您的会议邀请#{doc.title}有改动"
					if site
						text = "会议时间:#{start}\r会议地点:#{site}"
					else
						text = "会议时间:#{start}"
					#text = "会议时间:#{start}\r会议地点:#{site}"
					Push.send
						createdAt: new Date()
						createdBy: '<SERVER>'
						from: 'workflow',
						title: title,
						text: text,
						payload: payload
						badge: 12
						query: {userId:attendeeid,appName:"workflow"}
					user = db.users.findOne({_id:attendeeid}, {fields: {mobile: 1, utcOffset: 1, locale: 1, name: 1}})
					userPush = []
					userPush = Push.appCollection.find({userId:attendeeid,appName:"workflow"}).fetch()
					if userPush.length==0
						lang = 'en'
						if user.locale is 'zh-cn'
							lang = 'zh-CN'
						if doc.alarms.indexOf("Now")>=0
							SMSQueue.send
								Format: 'JSON',
								Action: 'SingleSendSms',
								ParamString: '',
								RecNum: user.mobile,
								SignName: '华炎办公',
								TemplateCode: 'SMS_67200967',
								msg: TAPi18n.__('sms.calendar_event.template', {event_action: "会议变更",event_title:doc.title, event_time:start, event_location: doc.site}, lang)
			Events.direct.update {parentId:obj.parentId}, {$set: 
				title:doc.title,
				start:doc.start,
				end:doc.end,
				allDay:doc.allDay,
				site:doc.site,
				participation:doc.participation,
				description:doc.description,
				alarms: doc.alarms,
				remindtimes: doc.remindtimes,
				attendees: doc.attendees,
				ownerId:doc.ownerId
				componenttype: doc.componenttype,
				lastmodified: doc.lastmodified,
				Isdavmodified:false,
				firstoccurence:doc.firstoccurence,
				lastoccurence: doc.lastoccurence,
				etag: doc.etag,
				size: doc.size,
				calendardata: doc.calendardata,
				parentId:doc.parentId
				},{ multi: true }
			events=Events.find({parentId:obj.parentId}).fetch()
			events.forEach (event)->
				isDefaultCalendar=Calendars.findOne({_id:event.calendarid}).isDefault
				if isDefaultCalendar
					Calendar.addChange(event.calendarid,event.uri,2)
		else
			Calendar.addCalendarObjects(obj.ownerId,obj,operation);
			Events.direct.update {parentId:obj.parentId}, {$set:
				attendees:obj?.attendees},{ multi: true }
			Events.direct.update {_id:obj._id}, {$set:
				alarms:obj.alarms
				remindtimes:obj.remindtimes}	
			events=Events.find({parentId:obj.parentId}).fetch()
			events.forEach (event)->
				isDefaultCalendar=Calendars.findOne({_id:event.calendarid}).isDefault
				if isDefaultCalendar
					Calendar.addChange(event.calendarid,event.uri,2)
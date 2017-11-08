import { Calendar } from '../main';
Meteor.methods
	removeEvents :(obj)->
		Events.direct.remove({_id:obj._id})
		Calendar.addChange(obj.calendarid,obj.uri,3);
		if obj.attendees
			if obj.ownerId==Meteor.userId()
				attendeesid=_.pluck(obj.attendees,'id');
				attendeesid.forEach (attendeeid)->
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
							#msg: TAPi18n.__('sms.remind.template', {instance_name: obj.title, deadline: obj.start, open_app_url: obj.site}, lang)
							msg: TAPi18n.__('sms.calendar_event', {event_action: "会议取消",event_title:obj.title, event_time: obj.start, event_location: obj.site}, lang)
					calendarid=Calendars.findOne({ownerId:attendeeid},{isDefault:true})._id
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

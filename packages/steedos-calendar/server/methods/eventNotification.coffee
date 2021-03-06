Meteor.methods
	eventNotification: (doc,userId,action) ->
		user = db.users.findOne({_id:userId}, {fields: {mobile: 1, utcOffset: 1, locale: 1, name: 1}})
		lang = 'en'
		if user.locale is 'zh-cn'
			lang = 'zh-CN'
		payload = 
			app: 'workflow'
			id: userId
			url:"/calendar"
			host:Meteor.absoluteUrl().substr(0, Meteor.absoluteUrl().length-1)
		utcOffset = db.users.findOne(userId)?.utcOffset
		unless utcOffset
			utcOffset = 8
		if doc.allDay
			start = moment(doc.start).utcOffset(utcOffset, false).format("YYYY-MM-DD")
		else
			start = moment(doc.start).utcOffset(utcOffset, false).format("YYYY-MM-DD HH:mm")
		site = doc.site
		if action == 1
			title = TAPi18n.__("event_invitation_new",{event_title:doc.title},lang)
			event_action = TAPi18n.__("event_action_new", {}, lang)
		else if action == 2
				title = TAPi18n.__("event_invitation_update",{event_title:doc.title},lang)
				#title = "您的会议邀请#{doc.title}有改动"
				event_action = TAPi18n.__("event_action_update", {}, lang)
			else if action == 3
					title = TAPi18n.__("event_invitation_cancle",{event_title:doc.title},lang)
					#title = "您的会议邀请#{doc.title}已取消"
					event_action = TAPi18n.__("event_action_cancle", {}, lang)
				else
					title = TAPi18n.__("event_invitation_alarm",{event_title:doc.title},lang)
					event_action =TAPi18n.__("event_action_alarm", {}, lang)
		if !site
			site =TAPi18n.__('event_undefined', {}, lang)
		text = TAPi18n.__("event_push_text",{event_time:start,event_site:site},lang)
		#text = "会议时间:#{start}\r会议地点:#{site}"			
		Push.send
			createdAt: new Date()
			createdBy: '<SERVER>'
			from: 'workflow',
			title: title,
			text: text,
			payload: payload
			badge: 12
			query: {userId:userId,appName:"workflow"}
		#userPush = db._raix_push_app_tokens.find({userId:attendeeid,appName:"workflow"})
		userPush = []
		userPush = Push.appCollection.find({'userId':userId,'appName':'workflow',$or:[{'token.gcm':{$in:[/.*huawei:.*/,/.*mi:.*/]}},{'token.apn':{$exists:1}}]}).fetch()
		if userPush.length==0 and doc.alarms.indexOf("Now")>=0 
			SMSQueue.send
				Format: 'JSON',
				Action: 'SingleSendSms',
				ParamString: '',
				RecNum: user.mobile,
				SignName: '华炎办公',
				TemplateCode: 'SMS_67200967',
				msg: TAPi18n.__('sms.calendar_event.template', {event_action:event_action,event_title:doc.title, event_time:start, event_location: site}, lang)
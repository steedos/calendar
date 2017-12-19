Meteor.methods
	eventNotification: (doc,userId,action) ->
		payload = 
			app: 'workflow'
			id: userId
			url:"/calendar"
			host:Meteor.absoluteUrl().substr(0, Meteor.absoluteUrl().length-1)
		utcOffset = db.users.findOne(userId)?.utcOffset
		unless utcOffset
			utcOffset = 8
		start = moment(doc.start).utcOffset(utcOffset, false).format("YYYY-MM-DD HH:mm")
		site = doc.site
		if action == 1
			title = "您有新的会议邀请#{doc.title}"
			event_action = "会议邀请"
		else if action == 2
				title = "您的会议邀请#{doc.title}有改动"
				event_action = "会议变更"
			else if action == 3
					title = "您的会议邀请#{doc.title}已取消"
					event_action = "会议取消"
				else
					title = "您的会议邀请#{doc.title}"
					event_action = "会议提醒"
		if site
			text = "会议时间:#{start}\r会议地点:#{site}"
		else
			text = "会议时间:#{start}"
			site ="未指定"
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
		if userPush.length==0
			user = db.users.findOne({_id:userId}, {fields: {mobile: 1, utcOffset: 1, locale: 1, name: 1}})
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
					msg: TAPi18n.__('sms.calendar_event.template', {event_action:'您的会议邀请',event_title:doc.title, event_time:start, event_location: site}, lang)
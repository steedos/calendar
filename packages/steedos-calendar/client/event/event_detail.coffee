EventDetailModal =
	switchAllDay: (isAllDay, value, input)->
		if Steedos.isMobile() or Steedos.isAndroidOrIOS()
			if isAllDay
				input.attr("type","date")
				value = moment(value).format("YYYY-MM-DD")
				input.val(value)
			else
				input.attr("type","datetime-local")
				value = moment(value).format("YYYY-MM-DDTHH:mm")
				input.val(value)
		else
			dp = input.data("DateTimePicker")
			unless dp
				return
			if isAllDay
				dp.format = "YYYY-MM-DD"
				dp.setValue(dp.date)
			else
				dp.format = "YYYY-MM-DD HH:mm"
				dp.setValue(dp.date)

Template.event_detail_modal.onCreated ->
	this.reactiveAttendees = new ReactiveVar()
	this.reactiveRemindtimes = new ReactiveVar()

Template.event_detail_modal.onRendered ->
	$("#event_detail_modal .modal-body").css("max-height",Steedos.getModalMaxHeight())

Template.event_detail_modal.helpers
	formTitle:()->
		option = Session.get "userOption"
		if option == "select"
			return t("new_event")
		else if option == "click"
			return t("calendar_info_event")

	showEventOptBox:()->
		# 事件是本人创建的/事件成员包含本人，都显示“保存”/“删除”操作
		obj = Template.instance().data
		calendars=Calendars.find().fetch()
		calendarIds=_.pluck(calendars,'_id')
		attendeesIds=_.pluck(obj.attendees,'id')
		if Meteor.userId()==obj.ownerId || attendeesIds.indexOf(Meteor.userId())>=0  
			if calendarIds.indexOf(obj.calendarid)>=0
				return true
			else
				return false
		else
			return false

	showActionBox:()->
		obj = Template.instance().data
		# ownerId = obj.ownerId
		# if ownerId == Meteor.userId()
		# 	return "none"
		onlyOne = obj?.attendees?.length<2 && obj?.attendees[0]?.id==Meteor.userId()
		calendars=Calendars.find().fetch()
		calendarIds=_.pluck(calendars,'_id')
		if onlyOne
			return "none"
		else
			attendeesIds=_.pluck(obj.attendees,'id')
			if attendeesIds.indexOf(Meteor.userId())<0
				return "none"
			else
				if calendarIds.indexOf(obj.calendarid)>=0
					return "block"
				else
					return "none"

	accendeeState:(state)->
		obj = Template.instance().data
		result = ""
		obj.attendees?.forEach (attendee)->
			if attendee.id == Meteor.userId()
				if attendee?.partstat==state
					result = "checked"
				if state=="TENTATIVE"&&attendee?.partstat=="NEEDS-ACTION"
					result = "checked"
		return result

	eventObj:()->
		obj = Template.instance().data
		if Template.instance().reactiveAttendees.get()
			obj.attendees = Template.instance().reactiveAttendees.get()
		obj.acceptednum=0
		obj.tentativenum=0	#不确定
		obj.declinednum=0
		obj.actionnum=0#待回复
		obj.curstat=""
		calendar=Calendars.findOne({_id:obj.calendarid}) 
		if Meteor.userId()==obj.ownerId and calendar
			obj.isOwner = "true"
			obj.formOpt = "normal"
		else
			obj.isOwner = "false"
			obj.formOpt = "disabled"
		obj.attendees?.forEach (attendee)->
			if attendee.id == Meteor.userId()
				obj.reason = attendee?.description
				switch attendee.partstat
					when "ACCEPTED" then obj.accepted==true
					when "TENTATIVE" then obj.tentative==true
					when "DECLINED" then obj.declined==true
					when "NEEDS-ACTION" then obj.action==true
			switch attendee.partstat
				when "ACCEPTED" then obj.acceptednum++
				when "TENTATIVE" then obj.tentativenum++
				when "DECLINED" then obj.declinednum++
				when "NEEDS-ACTION" then obj.actionnum++
		return obj

	isShowAddMembers: ()->
		ownerId = Template.instance().data.ownerId
		userId = Meteor.userId()
		return ownerId == userId

	add_membersFields: ()->
		fields =
			addmembers_event:
				autoform:
					type: 'selectuser'
					multiple: true
					spaceId: false
				optional: false
				type: [ String ]
				label: ''

		return new SimpleSchema(fields)

	values: ()->
		return {}

	isAlarmDisabled: ()->
		obj = Template.instance().data
		calendar = Calendars.findOne({_id:obj.calendarid})
		if calendar
			return false
		else
			return true

	partstatIcon: (partstat)->
		if partstat == "ACCEPTED"
			return "ion ion-checkmark-round"
		else if partstat == "TENTATIVE"
			return "fa fa-fw fa-question"
		else if partstat == "DECLINED"
			return "fa fa-fw fa-ban"
		else if partstat == "NEEDS-ACTION"
			return "fa fa-fw"

	isShowDeleteBtn: ()->
		option = Session.get "userOption"
		if option == "select"
			return false
		else if option == "click"
			return true

Template.event_detail_modal.events
	'click button.delete_events': (event, template)->
		obj = template.data
		Meteor.call('removeEvents',obj,
			(error,result) ->
				if !error
					$('[data-dismiss="modal"]').click()
		)
		

	'click button.save_events': (event, template)->
		unless AutoForm.validateForm("eventsForm")
			return
		$('body').addClass "loading"
		obj = Template.instance().data
		oldcalendarid=obj.calendarid
		if obj.calendarid!=AutoForm.getFieldValue("calendarid","eventsForm")
			if Session.get('defaultcalendarid')==AutoForm.getFieldValue("calendarid","eventsForm")
				relatetodefaultcalendar="Yes"
			else if Session.get('defaultcalendarid')==obj.calendarid
					relatetodefaultcalendar="No"
		else
			relatetodefaultcalendar = null
		if AutoForm.getFieldValue("calendarid","eventsForm") == undefined
			relatetodefaultcalendar = null

		# 用户是事件的接收者，表单处于只读状态，AutoForm.getFieldValue获取不到数据，需要赋值为obj原来的值
		obj.calendarid = AutoForm.getFieldValue("calendarid","eventsForm") || obj.calendarid
		obj.title = AutoForm.getFieldValue("title","eventsForm") || obj.title
		obj.start = AutoForm.getFieldValue("start","eventsForm") || obj.start
		obj.end = AutoForm.getFieldValue("end","eventsForm") || obj.end
		obj.description = AutoForm.getFieldValue("description","eventsForm") || obj.description
		obj.allDay = AutoForm.getFieldValue("allDay","eventsForm") || obj.allDay
		obj.alarms = AutoForm.getFieldValue("alarms","eventsForm") || obj.alarms
		members = []
		val=$('input:radio[name="optionsRadios"]:checked').val()
		description = $('textarea.description').val()
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				attendee.partstat=val
				attendee.description=description
		if !obj._id
			Meteor.call('eventInit',Meteor.userId(),obj,
				(error,result) ->
					if !error
						$('[data-dismiss="modal"]').click()
						$('body').removeClass "loading"
					else
						toastr.error t(error.reason)
			)
		else
			Meteor.call('updateEvents',obj,2,relatetodefaultcalendar,oldcalendarid,
				(error,result) ->
					if !error
						$('[data-dismiss="modal"]').click()
						$('body').removeClass "loading"
					else
						toastr.error t(error.reason)
						$('body').removeClass "loading"
				)
		calendarIds=Session.get("calendarIds")
		if calendarIds.indexOf(AutoForm.getFieldValue("calendarid","eventsForm"))<0
			calendarIds.push AutoForm.getFieldValue("calendarid","eventsForm")
			localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
			Session.set("calendarIds",calendarIds)			
		localStorage.setItem("calendarid:"+Meteor.userId(), AutoForm.getFieldValue("calendarid","eventsForm"))
		Session.set("calendarid",AutoForm.getFieldValue("calendarid","eventsForm"));
		return

	'click i.add-members': (event, template)->
		alarms = AutoForm.getFieldValue("alarms","eventsForm") || []
		template.reactiveRemindtimes.set(alarms)
		$("input[name='addmembers_event']").click()

	'change input[name="addmembers_event"]':(event, template)->
		addmembers = AutoForm.getFieldValue("addmembers_event","event-addmembers") || []
		obj = template.data
		obj.alarms = template.reactiveRemindtimes.get()
		Meteor.call('attendeesInit',obj,addmembers,
				(error,result) ->
					if !error
						template.reactiveAttendees.set(result.attendees)
						$("span.span-addmembers div.has-items").children().remove(".item")
			)
		AutoForm.resetForm("event-addmembers")

	'click i.delete-members': (event, template)->
		obj = template.data
		attendeeid = this.id
		tempAtt = []
		obj.attendees.forEach (attendee)->
			if attendee.id!=attendeeid
				tempAtt.push attendee
		template.reactiveAttendees.set(tempAtt)

	'change input[name=allDay]': (event, template)->
		data = template.data
		isAllDay = $(event.currentTarget).is(':checked')
		startInput = $("#event_detail_modal .modal-body input[name=start]")
		EventDetailModal.switchAllDay isAllDay, data.start, startInput
		endInput = $("#event_detail_modal .modal-body input[name=end]")
		EventDetailModal.switchAllDay isAllDay, data.end, endInput

	'shown.bs.modal #event_detail_modal': (event, template)->
		data = template.data
		isAllDay = data.allDay
		startInput = $("#event_detail_modal .modal-body input[name=start]")
		EventDetailModal.switchAllDay isAllDay, data.start, startInput
		endInput = $("#event_detail_modal .modal-body input[name=end]")
		EventDetailModal.switchAllDay isAllDay, data.end, endInput

	'change input[name=start]': (event, template)->
		data = template.data
		startInput = $("#event_detail_modal .modal-body input[name=start]")
		endInput = $("#event_detail_modal .modal-body input[name=end]")
		timespan = moment(startInput.val()).toDate() - data.start
		if Steedos.isMobile() or Steedos.isAndroidOrIOS()
			endValue = moment(data.end.getTime() + timespan)
			if endInput.attr("type") == "date"
				endInput.val(endValue.format("YYYY-MM-DD"))
			else
				endInput.val(endValue.format("YYYY-MM-DDTHH:mm"))
		else
			endDP = endInput.data("DateTimePicker")
			if endDP
				endDP.setValue(moment(data.end.getTime() + timespan))


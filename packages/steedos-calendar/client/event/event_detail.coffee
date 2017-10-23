import moment from 'moment'
EventDetailModal =
	switchAllDay: (isAllDay, input)->
		if Steedos.isMobile() or Steedos.isAndroidOrIOS()
			if isAllDay
				value = moment(input.val()).format("YYYY-MM-DD")
				input.attr("type","date")
				input.val(value)
			else
				value = moment(input.val()).format("YYYY-MM-DDTHH:mm")
				input.attr("type","datetime-local")
				input.val(value)
		else
			dp = input.data("DateTimePicker")
			unless dp
				return
			if isAllDay
				dp.format "YYYY-MM-DD"
				dp.date(dp.date())
			else
				dp.format "YYYY-MM-DD HH:mm"
				dp.date(dp.date())
		Session.set "isAllDay",isAllDay	
Template.event_detail_modal.onCreated ->
	this.reactiveAttendees = new ReactiveVar()
	this.reactiveRemindtimes = new ReactiveVar()
	this.isChooseAMPM = false
	Session.set("isAllDay", this.data?.allDay)

Template.event_detail_modal.onRendered ->

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
		attendeesIds=_.pluck(obj?.attendees,'id')
		if Meteor.userId()==obj.ownerId || attendeesIds.indexOf(Meteor.userId())>=0  
			if calendarIds.indexOf(obj.calendarid)>=0
				return true
			else
				return false
		else
			return false

	showActionBox:()->
		obj = Template.instance().data
		calendars=Calendars.find().fetch()
		calendarIds=_.pluck(calendars,'_id')
		attendeesIds=_.pluck(obj?.attendees,'id')
		calendarObj=Calendars.findOne({_id:obj.calendarid})
		if calendarObj.isDefault and attendeesIds.length==1 and Meteor.userId() == obj.ownerId
			return "none"
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
		if obj?.attendees
			obj.attendees.forEach (attendee)->
				if attendee.id == Meteor.userId()
					if attendee?.partstat==state
						result = "checked"
		return result

	eventObj:()->
		obj = Template.instance().data
		if Template.instance().reactiveAttendees.get()
			obj.attendees = Template.instance().reactiveAttendees.get()
			obj.start = moment($("#event_detail_modal .modal-body input[name=start]").val()).toDate()
			obj.end = moment($("#event_detail_modal .modal-body input[name=end]").val()).toDate()
		obj.acceptednum = 0
		obj.tentativenum = 0 #不确定
		obj.declinednum = 0
		obj.actionnum = 0 #待回复
		obj.curstat = ""
		calendar = Calendars.findOne({_id:obj.calendarid}) 
		if obj._id==obj.parentId and calendar
			obj.isOwner = "true"
			obj.formOpt = "normal"
		else
			obj.isOwner = "false"
			obj.formOpt = "disabled"
		if obj?.attendees
			obj.attendees.forEach (attendee)->
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
		try
			alarms_value_options = Events._simpleSchema._schema.alarms.autoform.options().getProperty("value")
			remove_v = []

			obj.alarms?.forEach (v)->
				if alarms_value_options.indexOf(v) < 0
					remove_v.push(v)

			remove_v.forEach (v)->
					console.log("obj.alarms.remove", v)
					obj.alarms.remove(obj.alarms.indexOf(v))
		catch e
			console.log e
		return obj

	isShowAddMembers: ()->
		ownerId = Template.instance().data.ownerId
		userId = Meteor.userId()
		return ownerId == userId

	add_membersFields: ()->
		is_with = Meteor.settings?.public?.calendar?.user_selection_within_user_organizations
		fields =
			addmembers_event:
				autoform:
					type: 'selectuser'
					multiple: true
					is_within_user_organizations: !!is_with
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
		oldcalendarid = obj.calendarid
		if obj.calendarid != AutoForm.getFieldValue("calendarid","eventsForm")
			if Session.get('defaultcalendarid') == AutoForm.getFieldValue("calendarid","eventsForm")
				relatetodefaultcalendar = "Yes"
			else if Session.get('defaultcalendarid') == obj.calendarid
					relatetodefaultcalendar = "No"
		else
			relatetodefaultcalendar = null
		if AutoForm.getFieldValue("calendarid","eventsForm") == undefined
			relatetodefaultcalendar = null

		# 用户是事件的接收者，表单处于只读状态，AutoForm.getFieldValue获取不到数据，需要赋值为obj原来的值
		if obj._id==obj.parentId
			obj.calendarid = AutoForm.getFieldValue("calendarid","eventsForm")
			obj.title = AutoForm.getFieldValue("title","eventsForm") 
			obj.description = AutoForm.getFieldValue("description","eventsForm") || ""
			obj.alarms = AutoForm.getFieldValue("alarms","eventsForm") || []
			obj.site = AutoForm.getFieldValue("site","eventsForm") || ""
			obj.participation = AutoForm.getFieldValue("participation","eventsForm") || ""
			obj.allDay = AutoForm.getFieldValue("allDay","eventsForm")
			if obj.allDay
				stHours = AutoForm.getFieldValue("start","eventsForm").getHours()
				stMinutes = AutoForm.getFieldValue("start","eventsForm").getMinutes()
				stSeconds = AutoForm.getFieldValue("start","eventsForm").getSeconds() 
				obj.start = new Date(AutoForm.getFieldValue("start","eventsForm").getTime()-stHours*60*60*1000-stMinutes*60*1000-stSeconds*1000) 
				endHours = AutoForm.getFieldValue("end","eventsForm").getHours()
				endMinutes = AutoForm.getFieldValue("end","eventsForm").getMinutes()
				endSeconds = AutoForm.getFieldValue("end","eventsForm").getSeconds() 
				if AutoForm.getFieldValue("start","eventsForm").getDate() == AutoForm.getFieldValue("end","eventsForm").getDate()
					obj.end = new Date(AutoForm.getFieldValue("end","eventsForm").getTime()-endHours*60*60*1000-endMinutes*60*1000-endSeconds*1000 + 24*60*60*1000)
				else
					obj.end = new Date(AutoForm.getFieldValue("end","eventsForm").getTime()-endHours*60*60*1000-endMinutes*60*1000-endSeconds*1000)
			else
				obj.start = AutoForm.getFieldValue("start","eventsForm")
				obj.end = AutoForm.getFieldValue("start","eventsForm")
		else
			obj.alarms = AutoForm.getFieldValue("alarms","eventsForm") || []

			
		members = []
		val = $('input:radio[name="optionsRadios"]:checked').val() || "NEEDS-ACTION"
		description = $('textarea.description').val()
		if val or description
			responsetime = new Date()
		if obj?.attendees
			obj.attendees.forEach (attendee)->
				if attendee.id == Meteor.userId()
					attendee.partstat = val
					attendee.description = description
					attendee.responsetime = responsetime
		if !obj._id
			Meteor.call('eventInit',Meteor.userId(),obj,
				(error,result) ->
					$('body').removeClass "loading"
					if !error
						$('[data-dismiss="modal"]').click()
					else
						toastr.error t(error.reason)
			)
		else
			Meteor.call('updateEvents',obj,2,relatetodefaultcalendar,oldcalendarid,
				(error,result) ->
					$('body').removeClass "loading"
					if !error
						$('[data-dismiss="modal"]').click()
					else
						toastr.error t(error.reason)
				)
		calendarIds=Session.get("calendarIds")
		if calendarIds.indexOf(AutoForm.getFieldValue("calendarid","eventsForm"))<0
			calendarIds.push AutoForm.getFieldValue("calendarid","eventsForm")
			localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
			Session.set("calendarIds",calendarIds)			
		localStorage.setItem("calendarid:"+Meteor.userId(), AutoForm.getFieldValue("calendarid","eventsForm"))
		Session.set("calendarid",AutoForm.getFieldValue("calendarid","eventsForm"));
		return

	'click .add-members': (event, template)->
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
		obj?.attendees.forEach (attendee)->
			if attendee.id!=attendeeid
				tempAtt.push attendee
		template.reactiveAttendees.set(tempAtt)

	'change input[name=allDay]': (event, template)->
		isAllDay = $(event.currentTarget).is(':checked')
		if isAllDay
			$("input[name='morning']").attr("checked",false)
			$("input[name='afternoon']").attr("checked",false)
		startInput = $("#event_detail_modal .modal-body input[name=start]")
		EventDetailModal.switchAllDay isAllDay, startInput
		endInput = $("#event_detail_modal .modal-body input[name=end]")
		EventDetailModal.switchAllDay isAllDay, endInput
		# 如果切换“全天”开关时开始时间大于结束时间，则把结束时间值设置为等于开始时间，避免保存时报“开始时间不能大于结束时间”
		if Steedos.isMobile() or Steedos.isAndroidOrIOS()
			startInputMoment = moment(startInput.val())
			endInputMoment = moment(endInput.val())
			startInputDate = startInputMoment.toDate()
			endInputDate = endInputMoment.toDate()
			if startInputDate > endInputDate
				if endInput.attr("type") == "date"
					endInput.val(startInputMoment.format("YYYY-MM-DD"))
				else
					endInput.val(startInputMoment.format("YYYY-MM-DDTHH:mm"))
		else
			startDP = startInput.data("DateTimePicker")
			endDP = endInput.data("DateTimePicker")
			if startDP and endDP and startDP.date().toDate() > endDP.date().toDate()
				endDP.date(startDP.date())

	'click input[name=morning]': (event, template)->
		template.isChooseAMPM = true
		$("input[name='allDay']").attr("checked",false)
		startInput = $("#event_detail_modal .modal-body input[name=start]")
		endInput = $("#event_detail_modal .modal-body input[name=end]")
		date = moment(startInput.val()).format("YYYY-MM-DD")
		startVal = moment("#{date} 08:30")
		endVal = moment("#{date} 12:00")
		EventDetailModal.switchAllDay false, startInput
		EventDetailModal.switchAllDay false, endInput
		if Steedos.isMobile() or Steedos.isAndroidOrIOS()
			startInput.val(startVal.format("YYYY-MM-DDTHH:mm"))
			endInput.val(endVal.format("YYYY-MM-DDTHH:mm"))
		else
			startDP = startInput.data("DateTimePicker")
			endDP = endInput.data("DateTimePicker")
			startDP.date(startVal)
			endDP.date(endVal)

	'click input[name=afternoon]': (event, template)->
		template.isChooseAMPM = true
		$("input[name='allDay']").attr("checked",false)
		startInput = $("#event_detail_modal .modal-body input[name=start]")
		endInput = $("#event_detail_modal .modal-body input[name=end]")
		date = moment(startInput.val()).format("YYYY-MM-DD")
		startVal = moment("#{date} 14:00")
		endVal = moment("#{date} 18:00")
		EventDetailModal.switchAllDay false, startInput
		EventDetailModal.switchAllDay false, endInput
		if Steedos.isMobile() or Steedos.isAndroidOrIOS()
			startInput.val(startVal.format("YYYY-MM-DDTHH:mm"))
			endInput.val(endVal.format("YYYY-MM-DDTHH:mm"))
		else
			startDP = startInput.data("DateTimePicker")
			endDP = endInput.data("DateTimePicker")
			startDP.date(startVal)
			endDP.date(endVal)


	'shown.bs.modal #event_detail_modal': (event, template)->
		data = template.data
		isAllDay = data.allDay
		startInput = $("#event_detail_modal .modal-body input[name=start]")
		EventDetailModal.switchAllDay isAllDay, startInput
		endInput = $("#event_detail_modal .modal-body input[name=end]")
		EventDetailModal.switchAllDay isAllDay, endInput
		if data.ownerId == Meteor.userId()
			$("input[name='title']").focus().select()

	'change input[name=start]': (event, template)->
		unless template.isChooseAMPM
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
					endDP.date(moment(data.end.getTime() + timespan))


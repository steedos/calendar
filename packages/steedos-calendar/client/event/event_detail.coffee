Template.event_detail_modal.onRendered ->
	$("#event_detail_modal .modal-body").css("max-height",Steedos.getModalMaxHeight())

Template.event_detail_modal.helpers
	showEventOptBox:()->
		# 事件是本人创建的/事件成员包含本人，都显示“保存”/“删除”操作
		debugger
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
		ownerId = obj.ownerId
		if ownerId == Meteor.userId()
			return "none"
		onlyOne = obj?.attendees?.length<2 && obj?.attendees[0].id==Meteor.userId()
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
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				if attendee?.partstat==state
					result = "checked"
				if state=="TENTATIVE"&&attendee?.partstat=="NEEDS-ACTION"
					result = "checked"
		return result

	eventObj:()->
		obj = Template.instance().data
		obj.acceptednum=0
		obj.tentativenum=0	#不确定
		obj.declinednum=0
		obj.actionnum=0#待回复
		obj.curstat=""
		if Meteor.userId()==obj.ownerId and obj._id==obj.parentId
			obj.isOwner = "true"
			obj.formOpt = "normal"
		else
			obj.isOwner = "false"
			obj.formOpt = "disabled"
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
		return obj

	isShowDeleteMember: (id) ->
		obj = Template.instance().data
		ownerId = obj.ownerId
		if id == ownerId
			return true

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
				optional: false
				type: [ String ]
				label: ''

		return new SimpleSchema(fields)

	values: ()->
		return {}

	isAlarmDisabled: ()->
		obj = Template.instance().data
		ownerId = obj.ownerId
		if ownerId == Meteor.userId()
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

Template.event_detail_modal.events
	'click button.delete_events': (event, template)->
		obj = template.data
		Meteor.call('removeEvents',obj,
			(error,result) ->
				console.log error
				if !error
					$('[data-dismiss="modal"]').click()
		)
		

	'click button.save_events': (event, template)->
		$('body').addClass "loading"
		obj = template.data
		if obj.calendarid!=AutoForm.getFieldValue("calendarid","eventsForm")
			if Session.get('defaultcalendarid')==AutoForm.getFieldValue("calendarid","eventsForm")
				relatetodefaultcalendar="Yes"
			else if Session.get('defaultcalendarid')==obj.calendarid
					relatetodefaultcalendar="No"
		else
			relatetodefaultcalendar = null
		if AutoForm.getFieldValue("calendarid","eventsForm") == undefined
			relatetodefaultcalendar = null
		console.log relatetodefaultcalendar
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

		Meteor.call('updateEvents',obj,2,relatetodefaultcalendar,
			(error,result) ->
				if !error
					$('[data-dismiss="modal"]').click()
					$('body').removeClass "loading"
				else
					toastr.error t(error.reason)
					$('body').removeClass "loading"
			)
		calendarIds=Session.get("calendarIds")
		if calendarIds.indexOf(AutoForm.getFieldValue("calendarid"))<0
			calendarIds.push AutoForm.getFieldValue("calendarid")
			localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
			Session.set 'calendarIds',calendarIds
			selectcalendarid=Session.set("calendarid",AutoForm.getFieldValue("calendarid"));
			localStorage.setItem("calendarid:"+Meteor.userId(), AutoForm.getFieldValue("calendarid"))
		return
	
	'click i.add-members': (event, template)->
		$("input[name='addmembers_event']").click()

	'change input[name="addmembers_event"]':(event, template)->
		addmembers = AutoForm.getFieldValue("addmembers_event","event-addmembers") || []
		obj = Session.get('cmDoc')
		Meteor.call('attendeesInit',obj,addmembers,
				(error,result) ->
					if !error
						Session.set 'cmDoc',result
						$("span.span-addmembers div.has-items").children().remove(".item")
			)
		AutoForm.resetForm("event-addmembers")

	'click i.delete-members': (event, template)->
		obj = Session.get('cmDoc')
		attendeeid = this.id
		tempAtt = []
		obj.attendees.forEach (attendee)->
		 	if attendee.id!=attendeeid
		 		tempAtt.push attendee
		obj.attendees = tempAtt
		Session.set 'cmDoc',obj
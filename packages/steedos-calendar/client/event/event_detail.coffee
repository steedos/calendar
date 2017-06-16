Template.event_detail_modal.onRendered ->
	$("#event_detail_modal .modal-body").css("max-height",Steedos.getModalMaxHeight())

Template.event_detail_modal.helpers
	showEventOptBox:()->
		# 事件是本人创建的/事件成员包含本人，都显示“保存”/“删除”操作
		obj = Session.get('cmDoc')
		calendars=Calendars.find().fetch()
		calendarIds=_.pluck(calendars,'_id')
		attendeesIds=_.pluck(obj.attendees,'id')
		if Meteor.userId()==obj.ownerId || attendeesIds.indexOf(Meteor.userId())>=0  
			 if calendarIds.indexOf(obj.calendarid)>=0
			 	return "inline"
			 else
			 	return "none"
		else
			return "none"

	showActionBox:()->
		obj = Session.get('cmDoc')
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
					return "inline"
				else
					return "none"

	accendeeState:(state)->
		obj = Session.get('cmDoc')
		result = ""
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				if attendee?.partstat==state
					result = "checked"
				if state=="TENTATIVE"&&attendee?.partstat=="NEEDS-ACTION"
					result = "checked"
		return result

	eventObj:()->
		obj = Session.get('cmDoc')
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
		obj = Session.get('cmDoc')
		ownerId = obj.ownerId
		if id == ownerId
			return true

	isShowAddMembers: ()->
		ownerId = Session.get('cmDoc').ownerId
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
		obj = Session.get "cmDoc"
		ownerId = obj.ownerId
		if ownerId == Meteor.userId()
			return false
		else
			return true

Template.event_detail_modal.events
	'click button.delete_events': (event)->
		obj = Session.get('cmDoc')
		Meteor.call('removeEvents',obj,
			(error,result) ->
				console.log error
				if !error
					$('[data-dismiss="modal"]').click()
		)
		

	'click button.save_events': (event)->
		$('body').addClass "loading"
		obj = Session.get('cmDoc')
		Meteor.call('updateEvents',obj,2,'',
			(error,result) ->
				Modal.hide('event_detail_modal')
				$('body').removeClass "loading"
			)
		$("#eventsForm").submit()

	'click input:radio[name="optionsRadios"]': (event)->
		description = $('textarea.description').val()
		obj = Session.get('cmDoc')
		val=$('input:radio[name="optionsRadios"]:checked').val()
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				attendee.partstat=val
				attendee.description=description
		Session.set 'cmDoc',obj
	
	'click i.add-members': ()->
		$("input[name='addmembers_event']").click()

	'change input[name="addmembers_event"]':()->
		addmembers = AutoForm.getFieldValue("addmembers_event","event-addmembers") || []
		obj = Session.get('cmDoc')
		Meteor.call('attendeesInit',obj,addmembers,
				(error,result) ->
					if !error
						Session.set 'cmDoc',result
						$("span.span-addmembers div.has-items").children().remove(".item")
			)
		AutoForm.resetForm("event-addmembers")

	'click i.delete-members': (event)->
		obj = Session.get('cmDoc')
		attendeeid = this.id
		tempAtt = []
		obj.attendees.forEach (attendee)->
		 	if attendee.id!=attendeeid
		 		tempAtt.push attendee
		obj.attendees = tempAtt
		Session.set 'cmDoc',obj


AutoForm.hooks eventsForm: 
	onSubmit: (insertDoc, updateDoc, currentDoc) ->
		$('body').addClass "loading"
		this.event.preventDefault()
		obj = Session.get("cmDoc")
		if obj.calendarid!=AutoForm.getFieldValue("calendarid")
			if Session.get('defaultcalendarid')==AutoForm.getFieldValue("calendarid")
				relatetodefaultcalendar="Yes"
			else if Session.get('defaultcalendarid')==obj.calendarid
					relatetodefaultcalendar="No"
		else
			relatetodefaultcalendar=null
		console.log relatetodefaultcalendar
		obj.calendarid = AutoForm.getFieldValue("calendarid")
		obj.title = AutoForm.getFieldValue("title")
		obj.start = AutoForm.getFieldValue("start")
		obj.end = AutoForm.getFieldValue("end")
		obj.description = AutoForm.getFieldValue("description")
		obj.allDay = AutoForm.getFieldValue("allDay")
		obj.alarms = AutoForm.getFieldValue("alarms")
		members = []
		val=$('input:radio[name="optionsRadios"]:checked').val()
		description = $('textarea.description').val()
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				attendee.partstat=val
				attendee.description=description

		that = this
		Meteor.call('updateEvents',obj,2,relatetodefaultcalendar,
			(error,result) ->
				$('[data-dismiss="modal"]').click()
				$('body').removeClass "loading"
				that.done()
			)
		calendarIds=Session.get("calendarIds")
		if calendarIds.indexOf(AutoForm.getFieldValue("calendarid"))<0
			calendarIds.push AutoForm.getFieldValue("calendarid")
			localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
			Session.set 'calendarIds',calendarIds
			selectcalendarid=Session.set("calendarid",AutoForm.getFieldValue("calendarid"));
			localStorage.setItem("calendarid:"+Meteor.userId(), AutoForm.getFieldValue("calendarid"))
		return

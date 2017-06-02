Template.event_detail_modal.onRendered ->

Template.event_detail_modal.helpers
	showEventOptBox:()->
		# 事件是本人创建的/事件成员包含本人，都显示“保存”/“删除”操作
		obj = Session.get('cmDoc')
		attendeesIds=_.pluck(obj.attendees,'id')
		if Meteor.userId()==obj.ownerId || attendeesIds.indexOf(Meteor.userId())>=0
			return "inline"
		else
			return "none"

	showActionBox:()->
		obj = Session.get('cmDoc')
		onlyOne = obj?.attendees?.length<2 && obj?.attendees[0].id==Meteor.userId()
		if onlyOne
			return "none"
		else
			attendeesIds=_.pluck(obj.attendees,'id')
			if attendeesIds.indexOf(Meteor.userId())<0
				return "none"
			else
				return "inline"

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
		if Meteor.userId()==obj.ownerId
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

Template.event_detail_modal.events
	'click button.delete_events': (event)->
		obj = Session.get('cmDoc')
		Meteor.call('removeEvents',obj,
			(error,result) ->
				if !error
					Modal.hide('event_detail_modal')
		)
		

	'click button.save_events': (event)->
		
		
	'click input:radio[name="optionsRadios"]': (event)->
		description = $('textarea.description').val()
		obj = Session.get('cmDoc')
		val=$('input:radio[name="optionsRadios"]:checked').val()
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				attendee.partstat=val
				attendee.description=description
		Session.set 'cmDoc',obj
			
	
	'click label.addmembers-lbl': (event)->
		addmembers = []
		addmembers = $("span.span-addmembers div.selectize-control div.selectize-input div.item").map(
			(i,n)->
				return $(n).attr("data-value")
			).toArray()
		obj = Session.get('cmDoc')
		Meteor.call('attendeesInit',obj,addmembers,
				(error,result) ->
					if !error
						Session.set 'cmDoc',result
						$("span.span-addmembers div.has-items").children().remove(".item")
			)

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
		Meteor.call('updateEvents',obj,2,
			(error,result) ->
				Modal.hide('event_detail_modal')
				$('body').removeClass "loading"
				that.done()
			)
		return

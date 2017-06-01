Template.event_detail_modal.onRendered ->



Template.event_detail_modal.helpers
	accendeeState:(state)->
		obj = Session.get('cmDoc')
		result = ""
		obj?.attendees.forEach (attendee)->
			if attendee?.id == Meteor.userId()
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
		if Meteor.userId()==obj?.ownerId and obj?._id==obj?.parentId
			obj.isOwner = "true"
			obj.formOpt = "update"
		else
			obj.isOwner = "false"
			obj.formOpt = "disabled"
		obj?.attendees.forEach (attendee)->
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
					$('div.modal-header button.close').trigger("click")
		)
		

	'click button.save_events': (event)->
		$('body').addClass "loading"
		obj = Session.get('cmDoc')
		members = []
		val=$('input:radio[name="optionsRadios"]:checked').val()
		description = $('textarea.description').val()
		obj?.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				attendee.partstat=val
				attendee.description=description
		Session.set 'cmDoc',obj
		obj = Session.get('cmDoc')
		Meteor.call('updateAttendees',obj,2,
			(error,result) ->
				if !error
					$('div.modal-header button.close').trigger("click")
					$('body').removeClass "loading"
			);
	'click input:radio[name="optionsRadios"]': (event)->
		description = $('textarea.description').val()
		obj = Session.get('cmDoc')
		val=$('input:radio[name="optionsRadios"]:checked').val()
		obj?.attendees.forEach (attendee)->
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
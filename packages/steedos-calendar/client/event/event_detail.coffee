
Template.event_detail_modal.onRendered ->



Template.event_detail_modal.helpers
	accendeeState:(state)->
		obj = Session.get('cmDoc')
		result = ""
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				if attendee?.partstat==state
					result = "checked"
				if state=="TENTATIVE"&&attendee?.partstat=="NEED-ACTION"
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
			obj.formOpt = "update"
		else
			obj.isOwner = "false"
			obj.formOpt = "disabled"
		obj.attendees.forEach (attendee)->
			if attendee.id == Meteor.userId()
				switch attendee.partstat
					when "ACCEPTED" then obj.accepted==true
					when "TENTATIVE" then obj.tentative==true
					when "DECLINED" then obj.declined==true
					when "NEED-ACTION" then obj.action==true
			switch attendee.partstat
				when "ACCEPTED" then obj.acceptednum++
				when "TENTATIVE" then obj.tentativenum++
				when "DECLINED" then obj.declinednum++
				when "NEED-ACTION" then obj.actionnum++
		return obj

Template.event_detail_modal.events
	'click button.save_events': (event)->
		$('body').addClass "loading"
		console.log 111111
		$('body').removeClass "loading"


	'click label.addmembers-lbl': (event)->
		console.log $("div.universe-selectize div.selectize-input div.item").attr("data-value")



	'click label.accepted': (event)->
		console.log Meteor.userId()

	'click label.tentative': (event)->
		console.log Meteor.userId()

	'click label.declined': (event)->
		swal({
			title: "拒绝会议", 
			text: "请输入拒绝原因：", 
			type: "input",
			showCancelButton: true,
			cancelButtonText:t("calendar_cancel"),
			confirmButtonColor: "#DD6B55",
			confirmButtonText: t("calendar_ok"),
			closeOnConfirm: false
		},
		(inputValue)->
			if inputValue==false
				return false;
			if inputValue==""
				swal.showInputError "请输入拒绝原因"
				return false
			console.log inputValue
			console.log Meteor.userId()
		)
	'click i.delete-members': (event)->
		console.log this.id
		swal({
			title: t("calendar_delete_confirm_calendar"),
			text: "确定删除此会议？",
			type: "warning",
			showCancelButton: true,
			cancelButtonText:t("calendar_cancel"),
			confirmButtonColor: "#DD6B55",
			confirmButtonText: t("calendar_ok"),
			closeOnConfirm: false,
			html: false
		},
		()->
			Calendars.remove {_id:calendar_id}, (error)->
				if error
					swal(t("calendar_delete_failed"),error.message,"error")
				else
					swal(t("calendar_delete_success"),t("calendar_delete_succsee_info"),"success")
		)
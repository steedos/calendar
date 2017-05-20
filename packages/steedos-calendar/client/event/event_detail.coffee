
Template.event_detail_modal.onRendered ->
	

Template.event_detail_modal.helpers
	eventObj:()->
		obj = Session.get('cmDoc')
		if Meteor.userId()==obj.ownerId
			obj.isOwner = "true"
			obj.formOpt = "update"
		else
			obj.isOwner = "false"
			obj.formOpt = "disabled"
		return obj

Template.event_detail_modal.events
	'click button.accepted': (event)->
		

	'click button.needs-action': (event)->


	'click button.declined': (event)->
		

	'click i.delete-members': (event)->
		console.log event
		console.log this
		calendar_id=this._id;
		swal({
		  title: t("calendar_delete_confirm_calendar"),
		  text: "你确定删除此日历吗？与此日历相关联的事件也都将被删除。",
		  type: "warning",
		  showCancelButton: true,
		  cancelButtonText:t("calendar_calend"),
		  confirmButtonColor: "#DD6B55",
		  confirmButtonText: t("calendar_ok"),
		  closeOnConfirm: false,
		  html: false
		},
		# 删除表中的记录
		()->
			# this._id取值无法删除，删除失败,this未定义
			Calendars.remove {_id:calendar_id}, (error)->
				if error
					swal(t("calendar_delete_failed"),error.message,"error");
				else
					swal(t("calendar_delete_success"),t("calendar_delete_succsee_info"),"success");
		);
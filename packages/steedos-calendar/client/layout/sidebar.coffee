import Calendar from '../core'

calendarsDep = new Tracker.Dependency;
calendarsRange = null
calendarsLoading = false


Template.calendarSidebar.helpers
	calendars: ()->
		userId= Meteor.userId()
		objs = Calendars.find()
		return objs
	isCalendarOwner: ()->
		return this.ownerId == Meteor.userId()
	isDefault :()->
		return this.isDefault
	isChecked :()->
		if calendarinstances.find({calendarid:this._id}).count()!=0
			return true
		else
			return false

Template.calendarSidebar.onRendered ->
	# 读取并刷新
# Template.calendarSidebar.on ->


Template.calendarSidebar.events
	'click div.check':(event)->
		checkBox = $(event.currentTarget.childNodes[1])
		checkBox.toggleClass("fa-check")
		Meteor.call('updateinstances',this._id,Meteor.userId(),checkBox.hasClass("fa-check"))
		# })
		Calendar.reloadEvents()
		# $("#calendar").fullCalendar("refetchEvents")

	'click .main-sidebar .calendar-add': (event)->
		$('.btn.calendar-add').click();

	'click i.calendar-edit': (event)->
		if Meteor.userId()!=this.ownerId
			swal(t("calendar_no_permission_calendar"),t("calnedar_no_permission_delete_calendar"),"warning");
			return;
		Session.set("cmDoc", this);
		$('.btn.calendar-edit').click();

	'click i.calendar-show': (event)->
		Session.set("cmDoc", this);
		$('.btn.calendar-show').click();
		

	'click i.calendar-delete': (event)->
		if Meteor.userId()!=this.ownerId
			swal(t("calendar_no_permission_calendar"),t("calnedar_no_permission_delete_calendar"),"warning");
			return;
		console.log(this);
		calendar_id=this._id;
		swal({
		  title: t("calendar_delete_calendar"),
		  text: t("calendar_delete_confirm_calendar"),
		  type: "warning",
		  showCancelButton: true,
		  cancelButtonText:t("calendar_cancel"),
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
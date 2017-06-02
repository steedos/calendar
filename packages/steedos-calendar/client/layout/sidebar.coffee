import Calendar from '../core'

calendarsDep = new Tracker.Dependency;
calendarsRange = null
calendarsLoading = false


Template.calendarSidebar.helpers
	calendars: ()->
		userId= Meteor.userId()
		objs = Calendars.find()
		return objs
	subscribe: ()->
		objs = calendarsubscriptions.find()
		return objs
	isCalendarOwner: ()->
		return this.ownerId == Meteor.userId()
	isDefault :()->
		return this.isDefault
	isChecked :()->
		calendarIds=Session.get('calendarIds')
		if calendarIds.indexOf(this?._id)<0
			return false
		else
			return true
	isCheck :()->
		calendarIds=Session.get('calendarIds')
		if calendarIds.indexOf(this.uri)<0
			return false
		else
			return true


Template.calendarSidebar.onRendered ->
	# 读取并刷新
# Template.calendarSidebar.on ->


Template.calendarSidebar.events
	'click label.resources-lbl': (event)->
		addmembers = []
		addmembers = $("span.span-resources div.selectize-control div.selectize-input div.item").map(
			(i,n)->
				return $(n).attr("data-value")
			).toArray()
		addmembers.forEach (addmember)->
			Meteor.call('initscription',addmember)
			#othercalendarsSub = new SubsManager()
			#othercalendarsSub.subscribe "othercalendars",addmember
			#objs = Calendars.find().fetch()


		$("span.span-resources div.has-items").children().remove(".item")

	'click div.check':(event)->
		calendarIds=Session.get('calendarIds')
		checkBox = $(event.currentTarget.childNodes[1])
		checkBox.toggleClass("fa-check")
		if this?.uri
			id = this.uri
		else
			id = this._id
		if checkBox.hasClass("fa-check")
			calendarIds.push(id)
		else
			dx = calendarIds.indexOf(id)
			calendarIds.splice(dx,1)
		Session.set 'calendarIds',calendarIds
		Calendar.reloadEvents()

	'click .main-sidebar .calendar-add': (event)->
		$('.btn.calendar-add').click();

	'click i.calendar-edit': (event)->
		if Meteor.userId()!=this.ownerId
			swal(t("calendar_no_permission"),t("calnedar_no_permission_delete_calendar"),"warning");
			return;
		Session.set("cmDoc", this);
		$('.btn.calendar-edit').click();

	'click i.calendar-show': (event)->
		Session.set("cmDoc", this);
		$('.btn.calendar-show').click();
		

	'click i.calendar-delete': (event)->
		$('body').addClass "loading"
		if Meteor.userId()!=this.ownerId
			swal(t("calendar_no_permission"),t("calnedar_no_permission_delete_calendar"),"warning");
			return;
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
				$('body').removeClass "loading"
				if error
					swal(t("calendar_delete_failed"),error.message,"error")
				else
					swal(t("calendar_delete_success"),t("calendar_delete_succsee_info"),"success")

		)



	'click i.calendar-hide': (event)->
		$('body').addClass "loading"
		if this?.uri
			calendar_id = this.uri
		else
			calendar_id = this._id
		swal({
		  title: t("calendar_hide_calendar"),
		  text: t("calendar_hide_confirm_calendar"),
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
				$('body').removeClass "loading"
				if error
					swal(t("calendar_hide_failed"),error.message,"error");
				else
					swal(t("calendar_hide_success"),t("calendar_hide_succsee_info"),"success");
		);
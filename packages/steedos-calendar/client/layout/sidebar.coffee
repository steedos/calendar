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
		if calendarIds!=undefined
			if calendarIds.indexOf(this?._id)>=0 || calendarIds.indexOf(this.uri)>=0
				return true
			else
				return false
		else
			return false
	calendarActive: ()->
		selectcalendarid=Session.get("calendarid");
		if selectcalendarid==undefined
			selectcalendarid=localStorage.getItem("calendarid:"+Meteor.userId());
		if selectcalendarid!=undefined and selectcalendarid==this._id
			return "active"
		else
			return ""

	add_membersFields: ()->
		fields =
			addmembers:
				autoform:
					type: 'selectuser'
					multiple: true
				optional: false
				type: [ String ]
				label: ''

		return new SimpleSchema(fields)

	values: ()->
		return {}


Template.calendarSidebar.onRendered ->
	if !Steedos.isMobile()
		$(".main-sidebar").perfectScrollbar({suppressScrollX: true})
	calendarsubscriptions.after.update (userId,doc)->
		Calendar.reloadEvents()
# Template.calendarSidebar.on ->

Template.calendarSidebar.events
	'click label.resources-lbl': (event)->
		addmembers = AutoForm.getFieldValue("addmembers","calendar-submembers") || []
		addmembers.forEach (addmember)->
			Meteor.call('initscription',addmember)
			#othercalendarsSub = new SubsManager()
			#othercalendarsSub.subscribe "othercalendars",addmember
			#objs = Calendars.find().fetch()


		$("span.span-resources div.has-items").children().remove(".item")

	'click div.check':(event)->
		# calendarIdsString=localStorage.getItem("calendarIds:"+Meteor.userId())
		calendarIds=[]
		# if !calendarIdsString
		# 	calendarIds=calendarIdsString.split(",")
		# 	console.log calendarIds
		if Session.get("calendarIds")
			calendarIds=Session.get("calendarIds")
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
		localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
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
	
	'click .my-calendar': (event)->
		selectcalendarid=Session.set("calendarid",this._id);
		#localStorage.removeItem("calendarid:"+Meteor.userId(), this._id)	
		localStorage.setItem("calendarid:"+Meteor.userId(), this._id)
		$('#calendar').fullCalendar("getCalendar")?.option("eventColor", this.color);
	'click i.subscribe-show': (event)->
		Session.set("cmDoc", this);
		$('.btn.subscribe-show').click();

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
					localStorage.setItem("calendarid:"+Meteor.userId(),Session.get('defaultcalendarid'))
					Session.set("calendarid",Session.get('defaultcalendarid'))
		)



	'click i.subscribe-hide': (event)->
		if this?.uri
			calendar_id = this.uri
		else
			calendar_id = this._id
		calendar_id=this._id;
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
			$('body').addClass "loading"
			# this._id取值无法删除，删除失败,this未定义
			Calendars.remove {_id:calendar_id}, (error)->
				$('body').removeClass "loading"
				calendarsubscriptions.remove {_id:calendar_id}, (error)->
				if error
					swal(t("calendar_hide_failed"),error.message,"error");
				else
					swal(t("calendar_hide_success"),t("calendar_hide_succsee_info"),"success");
		);

	'click i.sub-calendar':()->
		$("input[name='addmembers']").click()

	'change input[name="addmembers"]':()->
		addmembers = AutoForm.getFieldValue("addmembers","calendar-submembers") || []
		addmembers.forEach (addmember)->
			if addmember != Meteor.userId()
				Meteor.call('initscription',addmember)
		AutoForm.resetForm("calendar-submembers")

	'click i.add-event': ()->
		calendarid = Session.get 'calendarid'
		start = new Date()
		end = new Date()
		doc = {
			start: start
			end: end
			calendarid: calendarid
		}
		Meteor.call('eventInit',Meteor.userId(),doc,
			(error,result) ->
				
				$('body').removeClass "loading"
				if !error
					AutoForm.resetForm("eventForm")
					Session.set 'cmDoc', result
					Modal.show('event_detail_modal')
				else
					console.log error
			)

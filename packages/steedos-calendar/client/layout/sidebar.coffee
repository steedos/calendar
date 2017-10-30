import Calendar from '../core'
import moment from 'moment'

calendarsDep = new Tracker.Dependency;
calendarsRange = null
calendarsLoading = false


Template.calendarSidebar.helpers
	calendars: ()->
		objs = Calendars.find({$or:[{"ownerId":Meteor.userId()},{"members":Meteor.userId()},{"admins":Meteor.userId()}]}).fetch()
		defaultcalendarIndex = 0
		objs.forEach (obj,index) ->
			if obj.ownerId == Meteor.userId() and obj.isDefault == true
				defaultcalendarIndex = index
		defaultcalendar = objs.splice(defaultcalendarIndex,1)
		objs = defaultcalendar.concat(objs)
		return objs
	subscribe: ()->
		objs = calendarsubscriptions.find().fetch()
		subscriptions = 
			shares: []
			defaults: []
		objs.forEach (obj, index) ->
			selector = 
				_id: obj.uri
				members_readonly: Meteor.userId()
			if Calendars.findOne(selector)
				subscriptions.shares.push obj
			else
				subscriptions.defaults.push obj
			
		return subscriptions

	isCalendarEditable: ()->
		userId = Meteor.userId()
		admins = this?.admins || []
		if _.indexOf(admins,userId) >= 0 || this.ownerId == userId
			return true
		else
			return false
	isCalendarOwner: ()->
		return this?.ownerId == Meteor.userId()
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
		is_with = Meteor.settings?.public?.calendar?.user_selection_within_user_organizations
		fields =
			addmembers:
				autoform:
					type: 'selectuser'
					multiple: true
					is_within_user_organizations: !!is_with
				optional: false
				type: [ String ]
				label: ''

		return new SimpleSchema(fields)

	members_busyFields: ()->
		is_with = Meteor.settings?.public?.calendar?.user_selection_within_user_organizations
		fields =
			membersbusy:
				autoform:
					type: 'selectuser'
					multiple: true
					is_within_user_organizations: !!is_with
					defaultValue: ()->
						defaultcalendarid = Session.get "defaultcalendarid"
						defaultcalendarObj = Calendars.findOne({_id:defaultcalendarid})
						return defaultcalendarObj?.members_busy || []
				optional: false
				type: [ String ]
				label: ''

		return new SimpleSchema(fields)

	values: ()->
		return {}

	ShowMoreCalendars: ()->
		userId = Meteor.userId()
		browseCalendarIds = Calendars.find({members_readonly:Meteor.userId()}).fetch().getProperty("_id")
		subCalendars = calendarsubscriptions.find().fetch().getProperty("uri")
		ShowMoreCalendars = false
		browseCalendarIds.forEach (id,index) ->
			if _.indexOf(subCalendars,id) < 0
				ShowMoreCalendars = true
		return ShowMoreCalendars
		

	showAddCalendar: ()->
		spaceId = Session.get("spaceId")
		return Steedos.isSpaceAdmin(spaceId)

	eventNeedOptionCounts :()->
		calendarid = Session.get("defaultcalendarid")
		userId = Meteor.userId()
		today = moment(moment().format("YYYY-MM-DD 00:00")).toDate()
		selector = 
			{
				calendarid: calendarid,
				start: {$gte:today},
				"attendees": {
					$elemMatch: {
						id: userId,
						partstat: "NEEDS-ACTION"
					}
				}
			}
		return Events.find(selector).count()

	showSeparator:()->
		spaceId = Session.get("spaceId")
		defaultCalendarId = Session.get "defaultcalendarid"
		members = Calendars.findOne({_id:defaultCalendarId})?.members_busy_pending
		if members?.length > 0 or Steedos.isSpaceAdmin(spaceId)
			return true
		else
			return false

	showViewScription: ()->
		defaultCalendarId = Session.get "defaultcalendarid"
		members = Calendars.findOne({_id:defaultCalendarId})?.members_busy_pending
		if members?.length > 0 
			return true
		else
			return false

Template.calendarSidebar.onRendered ->
	calendarsubscriptions.after.update (userId,doc)->
		Calendar.reloadEvents()

Template.calendarSidebar.events
	'click label.resources-lbl': (event)->
		addmembers = AutoForm.getFieldValue("addmembers","calendar-submembers") || []
		addmembers.forEach (addmember)->
			Meteor.call('initscription',addmember)
		$("span.span-resources div.has-items").children().remove(".item")

	'click div.check':(event)->
		event.stopPropagation()
		calendarIds=[]
		if Session.get("calendarIds")
			calendarIds=Session.get("calendarIds")
		checkBox = $(event.currentTarget.childNodes[1])
		checkBox.toggleClass("ion-android-checkbox")
		if this?.uri
			id = this.uri
		else
			id = this._id
		if checkBox.hasClass("ion-android-checkbox")
			calendarIds.push(id)
		else
			dx = calendarIds.indexOf(id)
			calendarIds.splice(dx,1)
		localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
		Session.set 'calendarIds',calendarIds
		Calendar.reloadEvents()

	'click .add-members-busy': (event)->
		$('input[name="membersbusy"]').click()

	'change input[name="membersbusy"]': (event)->
		members = AutoForm.getFieldValue("membersbusy","calendar-members-busy") || []
		defaultcalendarid = Session.get "defaultcalendarid"
		Meteor.call("addMembersBusy",members,defaultcalendarid,
			(error,result) ->
				if error
					console.log error
		)

	'click .view-subscriptions': (event)->
		event.stopPropagation()
		Modal.show("members_busy_pending_modal")
		$(".dropdown-menu").removeClass("show-dropdown-menu")

	'click .main-sidebar .calendar-add': (event)->
		Session.set("cmDoc",{})
		Session.set("adminsEditable",true)
		$('.btn.calendar-add').click();

	'click .edit-calendar': (event)->
		$(".dropdown-menu").removeClass("show-dropdown-menu")
		userId = Meteor.userId()
		admins = this?.admins || []
		unless _.indexOf(admins,userId) >= 0 || this.ownerId == userId
			swal(t("calendar_no_permission"),t("calnedar_no_permission_delete_calendar"),"warning");
			return;
		Session.set("cmDoc", this);
		if this.ownerId == userId
			Session.set("adminsEditable",true)
		else
			Session.set("adminsEditable",false)
		$('.btn.calendar-edit').click();

	'click .show-calendar': (event)->
		event.stopPropagation()
		$(".dropdown-menu").removeClass("show-dropdown-menu")
		Session.set("cmDoc", this);
		$('.btn.calendar-show').click();
	
	'click .my-calendar': (event)->
		if Steedos.isMobile()
			# 手机上可能菜单展开了，需要额外收起来
			$("body").removeClass("sidebar-open")
		event.stopPropagation()
		event.preventDefault()
		currentCalendarid = Session.get("calendarid")
		Session.set("calendarIds",[this._id])
		localStorage.setItem("calendarIds:"+Meteor.userId(),[this._id])
		if currentCalendarid != this._id
			Session.set("calendarid",this._id)
			localStorage.setItem("calendarid:"+Meteor.userId(), this._id)
		path = FlowRouter.current().path
		if path == "/calendar/inbox"
			FlowRouter.go("/calendar/")

	'click .subscribe-calendar': (event)->
		if Steedos.isMobile()
			# 手机上可能菜单展开了，需要额外收起来
			$("body").removeClass("sidebar-open")
		event.stopPropagation()
		event.preventDefault()
		$(".dropdown-menu").removeClass("show-dropdown-menu")
		calendarid = Session.get("calendarid")
		if calendarid != this._id
			Session.set("calendarid",this._id)
			localStorage.setItem("calendarid:"+Meteor.userId(), this._id)
		Session.set("calendarIds",[this.uri])
		localStorage.setItem("calendarIds:"+Meteor.userId(),[this.uri])	
		path = FlowRouter.current().path
		if path == "/calendar/inbox"
			FlowRouter.go("/calendar/")

	'click .dropdown-toggle': (event)->
		event.stopPropagation()
		dropdownMenu = $(event.currentTarget).next()
		otherMenu = $(".dropdown-menu").not(dropdownMenu)
		otherMenu.removeClass("show-dropdown-menu")
		dropdownMenu.toggleClass("show-dropdown-menu")

	'click .main-sidebar': (event)->
		$(".dropdown-menu").removeClass("show-dropdown-menu")


	'click .show-subscribe': (event)->
		Session.set("cmDoc", this);
		$(".dropdown-menu").removeClass("show-dropdown-menu")
		$('.btn.subscribe-show').click();

	'click .calendar-delete': (event)->
		$(".dropdown-menu").removeClass("show-dropdown-menu")
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
				$('body').addClass "loading"
				Calendars.remove {_id:calendar_id}, (error)->
					$('body').removeClass "loading"
					if error
						swal(t("calendar_delete_failed"),error.message,"error")
					else
						Meteor.call("removeSubCalendars",calendar_id,
							(error,result) ->
								if error
									console.log error
						)
						swal {
							title:t("calendar_delete_success"),
							text:t("calendar_delete_succsee_info"),
							type:"success",
							confirmButtonText:t("OK")
						}
						localStorage.setItem("calendarid:"+Meteor.userId(),Session.get('defaultcalendarid'))
						Session.set("calendarid",Session.get('defaultcalendarid'))
		)

	'click .hide-subscribe': (event)->
		$(".dropdown-menu").removeClass("show-dropdown-menu")
		if this?.uri
			calendar_id = this.uri
		else
			calendar_id = this._id
		calendar_uri = this.uri
		calendar_id = this._id;
		swal({
				title: t("calendar_hide_calendar"),
				text: t("When_you_cancel_your_subscription_the_calendar_will_not_appear_in_your_shared_calendar"),
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
				calendarsubscriptions.remove {_id:calendar_id}, (error)->
					if error
						swal(t("calendar_hide_failed"),error.message,"error");
					else
						swal {
							title:t("calendar_hide_success"),
							type:"success",
							confirmButtonText:t('OK'),
						}
						$("body").removeClass "loading"
						calendarIds = Session.get("calendarIds")
						# 将删除的订阅日历从calendarIds中移除
						calendarIds = _.without(calendarIds,calendar_uri) 
						Session.set "calendarIds",calendarIds
						localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
		);

	'click .sub-calendar':()->
		$("input[name='addmembers']").click()

	'click .browse-calendars':()->
		Modal.show("subcalendar_modal")

	'click .browse-invations,.invating-counts':(event)->
		event.stopPropagation()
		$(".dropdown-menu").removeClass("show-dropdown-menu")
		if FlowRouter.current().path != "/calendar/inbox"
			FlowRouter.go("/calendar/inbox")

	'change input[name="addmembers"]':()->
		addmembers = AutoForm.getFieldValue("addmembers","calendar-submembers") || []
		addmembers.forEach (addmember)->
			if addmember != Meteor.userId()
				Meteor.call('initscription',addmember)
		AutoForm.resetForm("calendar-submembers")

	'click .mobile-sync': ()->
		Steedos.openWindow("https://www.steedos.com/cn/help/meeting/#手机同步（专业版）")


AutoForm.hooks calendarForm:
	onSuccess: (formType,result) ->
		calendarIds = Session.get("calendarIds")
		calendarIds.push(result._id)
		Session.set "calendarIds",calendarIds
		Session.set "calendarid",result._id
		localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
		localStorage.setItem("calendarid:"+Meteor.userId(),result._id)
		Meteor.call("shareCalendar",result,"new",
			(error,result) ->
				if error
					console.log error
		)

AutoForm.hooks editCalendarForm:
	onSuccess: (formType,result) ->
		calendarId = Session.get("cmDoc")._id
		title = AutoForm.getFieldValue("title","editCalendarForm")
		members_readonly = AutoForm.getFieldValue("members_readonly","editCalendarForm")
		color = AutoForm.getFieldValue("color","editCalendarForm")
		calendarObj = 
			_id: calendarId
			title: title
			members_readonly: members_readonly
			color: color
		Meteor.call("updateSubcalendar",calendarObj,
			(error,result) ->
				if error
					console.log error
		)
		Meteor.call("shareCalendar",calendarObj,"update",
			(error,result) ->
				if error
					console.log error
		)

import moment from 'moment'
import Calendar from '../core'

@moment = moment

Template.calendarContainer.onRendered ->
	if Steedos.isMobile()
		$("#calendar").on("swiperight", (event, options)->
			isSidebarOpen = $("body").hasClass('sidebar-open')
			if isSidebarOpen
				return
			if options.startEvnt.position.x > 40
				$('.fc-prev-button').trigger("click")
		)
		$("#calendar").on("swipeleft", (event, options)->
			isSidebarOpen = $("body").hasClass('sidebar-open')
			if isSidebarOpen
				return
			if options.startEvnt.position.x > 40
				$('.fc-next-button').trigger("click")
		)

	# if Steedos.isAndroidOrIOS()
	# 	isSwiping = false
	# 	loapTime = 0
	# 	loapX = 0
	# 	contentWrapperSelector = ".fc-view"
	# 	startX = 0
	# 	startOffsetX = 0
	# 	splitPx = 80
	# 	$("#calendar").on("touchstart", (event, options)->
	# 		isSidebarOpen = $("body").hasClass('sidebar-open')
	# 		if isSidebarOpen
	# 			return
	# 		startX = event.originalEvent.touches[0].clientX
	# 		if startX < 40
	# 			return
	# 		event.stopPropagation()
	# 		isSwiping = true
	# 		$(contentWrapperSelector).before("<div class='swipe-shadow-box'><i class='left-icon ion ion-android-arrow-back'></i><i class='right-icon ion ion-android-arrow-forward'></i></div>");
	# 	);
	# 	$("#calendar").on("touchend", (event, options)->
	# 		if startX < 40
	# 			startX = 0
	# 			return
	# 		event.stopPropagation()
	# 		startX = 0
	# 		unless isSwiping
	# 			return
	# 		isSwiping = false
	# 		if startOffsetX > splitPx
	# 			$('.fc-prev-button').trigger("click")
	# 		else if startOffsetX < -splitPx
	# 			$('.fc-next-button').trigger("click")
	# 		$(contentWrapperSelector).css("transform","translate(0, 0)")
	# 		startOffsetX = 0
	# 		$(".swipe-shadow-box").remove()
	# 	);
	# 	$("#calendar").on("touchmove", (event, options)->
	# 		if startX < 40
	# 			return
	# 		event.stopPropagation()
	# 		unless isSwiping
	# 			return
	# 		startOffsetX = event.originalEvent.touches[0].clientX - startX
	# 		$(contentWrapperSelector).css("transform","translate(#{startOffsetX}px, 0)")
	# 		$(".swipe-shadow-box").removeClass("swipe-left").removeClass("swipe-right").removeClass("left-icon").removeClass("right-icon")
	# 		if startOffsetX > 0
	# 			$(".swipe-shadow-box").addClass("swipe-left")
	# 			if startOffsetX > splitPx
	# 				$(".swipe-shadow-box").addClass("left-icon")
	# 			else
	# 				$(".swipe-shadow-box").addClass("right-icon")
	# 		else
	# 			$(".swipe-shadow-box").addClass("swipe-right")
	# 			if startOffsetX < -splitPx
	# 				$(".swipe-shadow-box").addClass("right-icon")
	# 			else
	# 				$(".swipe-shadow-box").addClass("left-icon")
	# 	);

	Tracker.afterFlush ->
		Calendar.generateCalendar();

eventsDep = new Tracker.Dependency
eventsSub = new SubsManager()

eventsRange = null
eventsLoading = false 

Calendar.reloadEvents = () ->
	eventsDep.depend()
	$("#calendar").fullCalendar("refetchEvents")


Calendar.generateCustomButtons = ()->
	if Steedos.isMobile()
		# 手机上去掉"2017年6 – 7月"后面的" – 7"显示为"2017年6月"
		viewTitle = $(".fc-header-toolbar .fc-center h2").eq(0).text()
		viewTitle = viewTitle.replace(/ – \d+/,"")
		# $(".fc-header-toolbar .fc-center h2").text(viewTitle) #这句话加上会造成横屏手机上跨月份时有标题跳转的动画
		if $(".fc-header-toolbar .fc-center span.fix-title").length
			$(".fc-header-toolbar .fc-center span.fix-title").text(viewTitle)
		else
			$(".fc-header-toolbar .fc-center h2").after("<span class='fix-title'>#{viewTitle}</span>")

	unless $("[data-toggle=offcanvas]").length 
		$("#calendar .fc-header-toolbar .fc-left").prepend('<button type="button" class="btn btn-default" data-toggle="offcanvas"><i class="fa fa-bars"></i></button>')

	unless $("button.btn-add-event").length
		$(".fc-button-group").prepend('<button type="button" class="btn btn-default btn-add-event"><i class="ion ion-plus-round"></i></button>')


Calendar.getEventsData = ( start, end, timezone, callback )->
	if !Meteor.userId()
		callback([])
		return
	calendarIds=Session.get('calendarIds')
	if !calendarIds
		calendarIds=[]
	calendar=Calendars.findOne({'_id':Session.get('calendarid')})
	$('#calendar').fullCalendar("getCalendar").getView().options.eventColor=calendar?.color
	utcOffsetHours = moment().utcOffset()/60
	start = start.subtract(utcOffsetHours, "hours").toDate()
	end = end.subtract(utcOffsetHours,"hours").toDate()
	params = 
		start: start
		end: end
		timezone: timezone
		calendar:calendarIds

	eventsSub.subscribe "calendar_objects", params
	Tracker.autorun (c)->
		if eventsSub.ready()
			Calendar.generateCustomButtons()

			query = calendarid: $in: params.calendar

			events = Events.find(query).fetch()
			events.forEach (event,index) ->
				if event.ownerId != Meteor.userId() && event.calendarid == Session.get("defaultcalendarid")
					event.attendees?.forEach (attendee)->
						if attendee.id == Meteor.userId() and attendee.partstat == 'DECLINED'
							events.remove(index)
			callback(events)				
			c.stop()

Calendar.hasPermission = ( event )->
	obj = Events.findOne({'_id':event._id})
	if (obj?.ownerId==Meteor.userId()&&obj?.parentId==obj?._id)
		return true
	else
		return false

Calendar.generateCalendar = ()->
	if !$('#calendar').children()?.length
		if Steedos.isMobile()
			rightHeaderView = 'month,listWeek,agendaDay'
			defaultView = 'listWeek'
			dayNamesShortValue = [t('Sun'), t('Mon'), t('Tue'), t('Wed'), t('Thu'), t('Fri'), t('Sat')]
			listWeekText = t("calendar_list_week_mobile")
		else
			rightHeaderView = 'month,agendaWeek,agendaDay,listWeek'
			defaultView = localStorage.getItem("defaultView:" + Meteor.userId()) || 'listWeek'
			dayNamesShortValue = undefined
			listWeekText = t("calendar_list_week")

		viewsOptions = {}
		if Steedos.isMobile()
			locale = Steedos.locale()
			switch locale
				when "zh-cn"
					viewsOptions.month =
						titleFormat: 'YYYY年M月'
					viewsOptions.agendaDay =
						titleFormat: 'YYYY年M月'
						columnFormat: 'dddd M月D日'
					viewsOptions.listWeek =
						titleFormat: 'YYYY年M月'
				else
					viewsOptions.month =
						titleFormat: 'MMM YYYY'
					viewsOptions.agendaDay =
						titleFormat: 'MMM YYYY'
						columnFormat: 'dddd M/D'
					viewsOptions.listWeek =
						titleFormat: 'MMM YYYY'
					break


		$('#calendar').fullCalendar
			height: ()->
				if Steedos.isMobile()
					return $('#calendar').height() - 2
				else
					return $('#calendar').height() - 2
			handleWindowResize: true
			header: 
				left: ''
				center: 'prev title next'
				right: rightHeaderView
			views: viewsOptions
			selectable: true
			selectHelper: true
			# weekends:false
			navLinks: true
			editable: true
			eventLimit: true
			weekNumbers:false
			nowIndicator: true
			defaultView:defaultView
			events: Calendar.getEventsData
			timeFormat: 'H:mm'
			timezone: 'local'
			locale: Session.get('steedos-locale')
			noEventsMessage:t("no_events_message")
			dayNamesShort:dayNamesShortValue
			buttonText:
				listWeek:listWeekText

			eventDataTransform: (event) ->
				calendar = Calendars.findOne({'_id':event.calendarid})
				color = ""
				if calendar
					color = calendar.color
					title = event.title
				else
					cs = calendarsubscriptions.findOne({'uri':event.calendarid})
					color = cs?.color
					title = t("busy")
				subCalendar = Calendars.findOne({'_id':event.calendarid,"members_readonly":Meteor.userId()})
				subCalendarInfo = calendarsubscriptions.findOne({'uri':event.calendarid})
				if subCalendarInfo
					color = calendarsubscriptions.findOne({'uri':event.calendarid}).color
				copy =
					id: event._id
					allDay: event.allDay
					title: title
					url:event.url
					color:color
					site: event.site
					participation: event.participation
					backgroundColor:color
					borderColor:color
				if event.start
					copy.start = moment(event.start)
				if event.end
					copy.end = moment(event.end)
				return copy

			eventRender: (event,element,view) ->
				Session.set "view",view.name
				if view.name == "listWeek"
					start = event.start?.format("H:mm")
					end = event.end?.format("H:mm")
					if event.allDay
						timeText = t "events_allday"
					else if end
						timeText = "#{start} - #{end}"
					else
						timeText = "#{start}"
					color = event.color 
					title = event.title
					site = event.site || ""
					participation = event.participation || ""
					tdContent = """
						<td class="fc-list-item-time fc-widget-content">#{timeText}</td>
						<td class="fc-list-item-title fc-widget-content"><span class="fc-event-dot" style="background-color:#{color}"></span><a>#{title}</a></td>
						<td class="fc-list-item-site fc-widget-content">#{site}</td>
						<td class="fc-list-item-participation fc-widget-content">#{participation}</td>
					"""
					element.html(tdContent)

			eventAfterAllRender: (view) ->
				start = view.start?._d?.getTime()	
				if view.name == "listWeek" and $(".fc-list-empty-wrap2").length
					$(".fc-list-empty-wrap2").remove()
					utcOffsetHours = moment().utcOffset()/60
					start = moment(start).subtract(utcOffsetHours, "hours").toDate()
					count = 0
					week = []
					while count < 7
						startMoment = moment(start)
						week.push(startMoment.add(24*count,"hours"))
						count++

					userLocale = db.users.findOne()?.locale
					weekContent = week.map (momentDay,index) ->
						dateToHref = momentDay.format("YYYY-MM-DD")
						if userLocale == "zh-cn"
							dayAlt = momentDay.format("YYYY年MM月DD日")
							dayMain = t(momentDay.format("dddd"))
						else
							dayAlt = momentDay.format("LL")
							dayMain = t(momentDay.format("dddd"))
						dataGoto = JSON.stringify({
							date : dateToHref,
							type : "day"
						}).replace(/\"/g,"&quot;")
						return """
							<tr class="fc-list-heading" data-date="#{dateToHref}">
								<td class="fc-widget-header" colspan="5">
									<a class="fc-list-heading-main" data-goto="#{dataGoto}">#{dayMain}</a>
									<a class="fc-list-heading-alt" data-goto="#{dataGoto}">#{dayAlt}</a>
								</td>
							</tr>
							<tr class="fc-list-item">
								<td class="fc-list-item-time fc-widget-content" colspan="4" style=""></td>
							</tr>
						"""

					weekContent = weekContent.join("")
					tableContent = """
						<table class="fc-list-table">
							<tbody>
								#{weekContent}
							</tbody>
						</table>
					"""
					$(".fc-scroller").prepend(tableContent);

				localStorage.setItem("defaultView:"+Meteor.userId(),view.name)
				if view.name == "listWeek"
					thead = """
						<tr class="fc-list-header">
							<td class="fc-list-item-time fc-widget-content">#{t('calendar_objects_time')}</td>
    						<td class="fc-list-item-title fc-widget-content">#{t('calendar_objects_title')}</td>
    						<td class="fc-list-item-site fc-widget-content">#{t('calendar_objects_site')}</td>
    						<td class="fc-list-item-participation fc-widget-content">#{t('calendar_objects_participation')}</td>
						</tr>
					"""
					$(".fc-list-table > tbody").prepend(thead)
					$(".fc-widget-header").attr("colspan","5") 
					headeringArr = $(".fc-list-heading-alt")

					#列表页面添加打印按钮
					unless Steedos.isAndroidOrIOS() or Steedos.isMobile()
						unless $("button.btn-print").length
							$(".fc-list-table").after('<button type="button" class="btn btn-default btn-print"><i class="ion ion-printer"></i></button>')
				else
					$("button.btn-print").remove()

				# if Steedos.isAndroidOrIOS or Steedos.isMobile()
				# 	height = $(".fc-widget-content > .fc-scroller").height() - 50
				# 	$(".fc-widget-content > .fc-scroller").css({"height":"#{height}px"})

			select: (start, end, jsEvent, view, resource)->
				objs = Calendars.find().fetch()
				mycalendarids=_.pluck(objs,'_id')
				Session.set "userOption","select" 
				calendarid = Session.get 'calendarid'
				if calendarid==undefined or mycalendarids.indexOf(calendarid)<0
						objs.forEach (obj) ->
							if obj.isDefault
								calendarid = obj._id
				calendarIds=Session.get('calendarIds')
				if calendarIds.indexOf(calendarid)<0
					calendarIds.push(calendarid)
					Session.set('calendarIds',calendarIds)
					localStorage.setItem("calendarIds:"+Meteor.userId(),calendarIds)
				Session.set "userId",Meteor.userId()
				Session.set "userOption","select"
				userId= Meteor.userId()
				
				doc = {
					calendarid:calendarid,
					ownerId:Meteor.userId(),
					start: start.toDate(),
					end: end.toDate()
				}
				if $(jsEvent.target).closest(".fc-day-grid.fc-unselectable").length
					# 从全天区域新建事件应该设置allDay属性
					doc.allDay = true
				Modal.show('event_detail_modal',doc)

			eventClick: (calEvent, jsEvent, view)->
				Session.set "userOption","click"
				event = Events.findOne
					_id: calEvent?.id
				calendarids = Calendars.find().fetch()?.getProperty("_id")
				if _.indexOf(calendarids,event?.calendarid) > -1
					if event
						Session.set "eventCalendarId",event.calendarid
						Modal.show('event_detail_modal', event)
						AutoForm.resetForm("eventsForm")
				else
					toastr.info t("this_event_is_belong_to_subscription_you_cannot_read_the_detail")

			eventDrop: (event, delta, revertFunc)->
				hasPermission = Calendar.hasPermission(event)
				if !hasPermission
					swal(t("calendar_no_permission"),t("calnedar_no_permission_modify_event"),"warning");
					Calendar.reloadEvents()
					return

				obj = Events.findOne({'_id':event._id})
				obj.allDay = event.allDay
				obj.start = event.start.toDate()
				if event.end == null
					obj.end = event.start.toDate()
				else
					obj.end = event.end.toDate()
				Meteor.call('updateEvents',obj,2,
					(error,result)->
						if error
							console.log error
				)

			eventResize: (event, delta, revertFunc, jsEvent, ui, view)->
				hasPermission = Calendar.hasPermission(event)
				if !hasPermission
					swal(t("calendar_no_permission"),t("calnedar_no_permission_modify_event"),"warning");
					Calendar.reloadEvents()
					return
				obj = Events.findOne({'_id':event._id})
				obj.start = event.start.toDate()
				obj.end = event.end.toDate()
				Meteor.call('updateEvents',obj,2)
				
		Events.find().observe
			added: (id, fields) ->
				eventsDep.changed();
			changed: () ->
				eventsDep.changed();
			removed: () ->
				eventsDep.changed();

		Tracker.autorun ()->
			Calendar.reloadEvents();

	else
		Calendar.reloadEvents();


Template.calendarContainer.events
	'click .btn-add-event': ()->
		objs = Calendars.find().fetch()
		mycalendarids=_.pluck(objs,'_id')
		Session.set "userOption","select" 
		calendarid = Session.get 'calendarid'
		if calendarid==undefined or mycalendarids.indexOf(calendarid)<0
				objs.forEach (obj) ->
					if obj.isDefault
						calendarid = obj._id
		start = moment(moment(new Date()).format("YYYY-MM-DD HH:mm")).toDate()
		end = moment(moment(new Date()).format("YYYY-MM-DD HH:mm")).toDate()
		userId = Meteor.userId()
		
		
		doc = {
			calendarid:calendarid,
			ownerId:userId,
			start: start,
			end: end
		}
		Modal.show('event_detail_modal',doc)

	'click button.btn-print':() ->
		$(".toast").hide()
		header = $(".fc-center h2").text()
		$(".fc-list-table").printThis({
			loadCSS: "/packages/steedos_calendar/client/layout/print.css",
			header: "<span class='header'>#{header}</span>"
		})

	'click .btn-view-month':() ->
		$('#calendar').fullCalendar('changeView', 'month')

	'click .btn-view-day':() ->
		$('#calendar').fullCalendar('changeView', 'agendaDay')

	'click .btn-view-list-week':() ->
		$('#calendar').fullCalendar('changeView', 'listWeek')
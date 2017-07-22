

import moment from 'moment'
import Calendar from '../core'

@moment = moment

Template.calendarContainer.onRendered ->
	Tracker.afterFlush ->
		Calendar.generateCalendar();

eventsDep = new Tracker.Dependency
eventsSub = new SubsManager()

eventsRange = null
eventsLoading = false 

Calendar.reloadEvents = () ->
	eventsDep.depend()
	$("#calendar").fullCalendar("refetchEvents")


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
			unless $("[data-toggle=offcanvas]").length 
				$("#calendar .fc-header-toolbar .fc-left").prepend('<button type="button" class="btn btn-default" data-toggle="offcanvas"><i class="fa fa-bars"></i></button>')
			unless $("button.btn-add-event").length
				$(".fc-button-group").prepend('<button type="button" class="btn btn-default btn-add-event"><i class="ion ion-plus-round"></i></button>')
			events = Events.find({calendarid:{$in: params.calendar}}).fetch()
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
			rightHeaderView = 'month,agendaDay,listWeek'
			defaultView = 'listWeek'
			dayNamesShortValue = [t('Sun'), t('Mon'), t('Tue'), t('Wed'), t('Thu'), t('Fri'), t('Sat')]
			listWeekText = t("calendar_list_week_mobile")
		else
			rightHeaderView = 'month,agendaWeek,agendaDay,listWeek'
			defaultView = localStorage.getItem("defaultView"+Meteor.userId()) || 'listWeek'
			dayNamesShortValue = undefined
			listWeekText = t("calendar_list_week")
		$('#calendar').fullCalendar
			height: ()->
				return $('#calendar').height() - 2
			handleWindowResize: true
			header: 
				left: ''
				center: 'prev title next'
				right: rightHeaderView
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

			eventRender:(event,element,view) ->
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

			eventAfterAllRender:(view) ->
				localStorage.setItem("defaultView"+Meteor.userId(),view.name)
				if view.name == "listWeek"
					thead = """
    					<tr class="fc-list-header">
    						<td class="fc-list-item-time fc-widget-content">时间</td>
    						<td class="fc-list-item-title fc-widget-content">内容</td>
    						<td class="fc-list-item-site fc-widget-content">地点</td>
    						<td class="fc-list-item-participation fc-widget-content">参加人员</td>
    					</tr>
					"""
					$(".fc-list-table > tbody").prepend(thead)
					$(".fc-widget-header").attr("colspan","5") 
					headeringArr = $(".fc-list-heading-alt")

			select: (start, end, jsEvent, view, resource)->
				objs = Calendars.find()
				calendarid = Session.get('calendarid')
				if calendarid==undefined
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
	'click button.btn-add-event': ()->
		Session.set "userOption","select" 
		calendarid = Session.get 'calendarid'
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

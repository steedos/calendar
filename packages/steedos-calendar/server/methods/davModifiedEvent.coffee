Meteor.methods
	davModifiedEvent: () ->
		events=Events.find({Isdavmodified:true,componenttype:"VEVENT"})		
		ICAL = require('ical.js');
		events?.forEach (obj)->
			jcalData = ICAL?.parse(obj.calendardata);
			vcalendar = new ICAL.Component(jcalData);
			vevent = vcalendar.getFirstSubcomponent('vevent');
			if vevent.getFirstPropertyValue('summary')!=null
				obj.title = vevent.getFirstPropertyValue('summary').toString();
			else
				obj.title = "Event Title"
			if vevent.getFirstPropertyValue('location')!=null
				obj.site=vevent.getFirstPropertyValue('location')
			if vevent.getFirstPropertyValue('description')!=null
				obj.description = vevent.getFirstPropertyValue('description').toString();
			start =vevent.getFirstPropertyValue('dtstart').toString()
			start=new Date(start)
			obj.start = new Date(start-8*60*60*1000)
			end =vevent.getFirstPropertyValue('dtend').toString()
			end=new Date(end)
			obj.end=new Date(end-8*60*60*1000)
			if (obj.end - obj.start)%86400000==0
				obj.allDay = true
			else
				obj.allDay = false
			
			#obj.ownerId =Meteor.userId()
			props = vevent.getAllProperties('attendee')
			len = props.length
			newattendees=[]
			if len
				i = 0
				while i < len
					mailto=props[i].getValues()
					users=Meteor.users.findOne({steedos_id:mailto[0].substr(7)},{field:{_id:1,name:1}})
					if props[i].getParameter("partstat")
						partstat=props[i].getParameter("partstat")
					else
						partstat="NEEDS-ACTION"
					if props[i].getParameter("role")
						role=props[i].getParameter("role")
					else
						role ="REQ-PARTICIPANT"
					attendee = {
						role:role,
						cutype:props[i].getParameter("cutype"),
						partstat:partstat
						mailto:mailto[0].substr(7)
						cn:users?.name
						id:users?._id	
						}
					newattendees.push attendee
					i++
			else
				user=Meteor.users.findOne({_id:obj.ownerId},{field:{steedos_id:1,name:1}})
				attendee = {
					role:"REQ-PARTICIPANT",
					cutype:"INDIVIDUAL",
					partstat:"ACCEPTED",
					cn:user?.name,
					mailto:user?.steedos_id,
					id:obj.ownerId,
					description:null}
				newattendees.push attendee
			obj.attendees=newattendees
			alarms = vevent.getAllSubcomponents('valarm')
			len = alarms.length
			if len
				newalarms=[]
			j = 0
			while j < len
				newalarms.push alarms[j].getFirstPropertyValue('trigger').toString()
				j++
			obj.alarms=[]
			if newalarms
				newalarms.forEach (newalarm)->
					if newalarm[0]=='-' or newalarms[0]=='P'
						obj.alarms.push  newalarm
			oldcalendarid=Events.findOne({uid:obj.uid}).calendarid
			defaultcalendarid = Calendars.findOne({ownerId:obj.ownerId},{isDefault:true})._id
			if oldcalendarid
				if obj.calendarid!=oldcalendarid
					if defaultcalendarid==obj.calendarid
						relatetodefaultcalendar="Yes"
					else if oldcalendarid==defaultcalendarid
							relatetodefaultcalendar="No"
				else
					relatetodefaultcalendar = null
			Meteor.call('updateEvents',obj,2,relatetodefaultcalendar,oldcalendarid)
		return

Meteor.startup ->
	if Meteor.settings.cron?.calendar_dav_interval
		Calendar.davTimeout = (time)->
			Meteor.setTimeout(()->
				Meteor.call('davModifiedEvent')
				Calendar.davTimeout(time)
			,time)

		Calendar.davTimeout Meteor.settings.cron.calendar_dav_interval

	 
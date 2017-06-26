Meteor.methods
	davModifiedEvent: () ->
		events=Events.find().fetch()
		events.forEach (obj)->
			if obj.Isdavmodified
				console.log obj
				jcalData = ICAL.parse(obj.calendardata);
				vcalendar = new ICAL.Component(jcalData);
				vevent = vcalendar.getFirstSubcomponent('vevent');
				obj.title = vevent.getFirstPropertyValue('summary').toString();
				start =vevent.getFirstPropertyValue('dtstart').toString()
				start=new Date(start)
				obj.start = new Date(start-8*60*60*1000)
				end =vevent.getFirstPropertyValue('dtend').toString()
				end=new Date(end)
				obj.end=new Date(end-8*60*60*1000)
				obj.ownerId =Meteor.userId()
				obj.parentId = obj._id
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
				obj.alarms=newalarms
				Meteor.call('updateEvents',obj,2,'','')
		return


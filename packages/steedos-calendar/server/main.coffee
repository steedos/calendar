import { Meteor } from 'meteor/meteor';
icalendar = require('icalendar');
MD5 = require('MD5');
uuid = require('uuid');
@moment_timezone = require('moment-timezone');
Meteor.startup ->
	
@Calendar = 
	#更新日历，新建事件，更新事件，删除事件会触发此函数。operation:1新建，2更新，3删除
	addChange : (calendarId, objectUri, operation)->
		oldsynctoken = Calendars.findOne({_id:calendarId}).synctoken;
		calendarchanges.direct.insert
			uri:objectUri,
			synctoken: oldsynctoken,
			calendarid: calendarId,
			operation: operation
		Calendars.direct.update({_id:calendarId},{$set:{synctoken:oldsynctoken+1}});
	#被分享的成员比创建者多share_herf,share_displayname. 
	#access对应 1 = owner, 2 = readonly, 3 = readwrite
	addInstance : (userId,doc,calendarid,steedosId,access,herf,displayname)->
		if doc.visibility == 'private'
			transp = false;
		else
			transp = true;
		#console.log doc.timezone
		zones=moment_timezone.tz.zone(doc.timezone);
		#console.log zones
		ical = new icalendar.iCalendar();
		vtimezone=ical.addComponent('VTIMEZONE');
		vtimezone.addProperty("TZID",doc.timezone);
		standard = vtimezone.addComponent("STANDARD");
		standard.addProperty("TZOFFSETFROM","0"+(-zones.offsets[0])/60+"00");
		standard.addProperty("TZOFFSETTO","0"+(-zones.offsets[1])/60+"00");
		standard.addProperty("TZNAME",zones.abbrs[0]);
		timezone = ical.toString();
		calendarinstances.insert
			principaluri:"principals/" + steedosId,
			transparent:transp,
			access:access,
			share_invitestatus:2,
			calendarid: calendarid,
			displayname:doc.title,
			description:"null",
			uri:calendarid,
			calendarorder:3,
			calendarcolor: doc.color,
			timezone :timezone,
			share_herf:herf,
			share_displayname: displayname
	
	addAttendees :(userId,doc,operation)->
		newattendees=[]
		if operation==2
			oldattendees=Events.findOne({_id:doc._id}).attendees
		else
			oldattendees=[]
		for member,i in doc.members
			partstat="NEEDS-ACTION"
			steedosId=Meteor.users.findOne({_id:member}).steedos_id
			oldattendees.forEach (attendee)->
				if attendee.mailto!=steedosId
					partstat = attendee.partstat
			attendee = {
				role:"REQ-PARTICIPANT",
				cutype:"INDIVIDUAL",
				partstat:partstat,
				cn:steedosId,
				mailto:steedosId,
				id:member
			}
			if member == userId
				attendee.partstat="ACCEPTED"  #得该

			newattendees.push attendee

		doc.attendees=newattendees
		return newattendees	
	shareEvent:(doc)->
		calendarmembers=Calendars.findOne({_id:doc.calendarid}).members
		newmembers=_.difference doc.members,calendarmembers;
		newmembers.forEach (member)->
			calendar=Calendars.findOne({ownerId:member},{isDefault:true}, {fields:{_id: 1,color:1}})
			console.log "calendar==="
			if calendar==undefined
				Meteor.call('calendarInit',member,Defaulttimezone);
				calendar=Calendars.findOne({ownerId:member},{isDefault:true}, {fields:{_id: 1,color:1}})
			Events.direct.insert
				title:doc.title
				members:doc.members
				start:doc.start
				end:doc.end
				allDay:doc.allDay
				calendarid:calendar._id
				description:doc.description
				alarms:doc.alarms
				componenttype:doc.componenttype
				uid:doc.uid
				uri:doc.uri
				ownerId:doc.ownerId
				lastmodified:doc.lastmodified
				firstoccurence:doc.firstoccurence
				lastoccurence:doc.lastoccurence
				attendees:doc.attendees
				calendardata:doc.calendardata
				etag:doc.etag
				size:doc.size
				eventcolor:calendar.color
				parentId:doc._id

	#新建或跟更新事件，事件对应的calendardata
	addEvent :(userId, doc,operation)->
		ical = new icalendar.iCalendar();
		vevent = new icalendar.VEvent(doc._id);
		timezone=Calendars.findOne({_id:doc.calendarid}).timezone;
		zones=moment_timezone.tz.zone(timezone);
		vtimezone=ical.addComponent('VTIMEZONE');
		ical.addComponent(vevent);
		vtimezone.addProperty("TZID",zones.name);
		standard = vtimezone.addComponent("STANDARD");
		standard.addProperty("TZOFFSETFROM","0"+(-zones.offsets[0])/60+"00");
		standard.addProperty("TZOFFSETTO","0"+(-zones.offsets[1])/60+"00");
		standard.addProperty("TZNAME",zones.abbrs[0]);
		date=new Date(2017/5/1);
		standard.addProperty("DTSTART",date);
		if doc.alarms !=undefined
			alarm = vevent.addComponent('VALARM');
			alarm.addProperty("ACTION", 'DISPLAY');
			alarm.addProperty("TRIGGER;VALUE=DURATION", doc.alarms);
			alarm.addProperty("DESCRIPTION","Default Mozilla Description"); 
		vevent.setDescription(doc.description);
		vevent.addProperty("TRANSP","OPAQUE");#得改
		vevent.addProperty("CREATED",new Date());
		vevent.addProperty("LAST-MODIFIED",new Date());
		vevent.setSummary(doc.title);
		vevent.addProperty("ORGANIZER;RSVP=TRUE;PARTSTAT=ACCEPTED;ROLE=CHAIR:mailto",Meteor.users.findOne({_id:userId}).steedos_id);
		vevent.setLocation("Shanghai"); 
		attendees=Calendar.addAttendees(userId,doc,operation);
		attendees.forEach (attendee)->
			attendee_string="ATTENDEES;"+"CUTYPE="+attendee.cutype+";ROLE="+attendee.role+";CN="+attendee.cn+";PARTSTAT="+attendee.partstat+";mailto"
			vevent.addProperty(attendee_string, attendee.mailto)
		if doc.allDay==true
			vevent.addProperty("DTSTART;VALUE=DATE",moment(new Date(doc.start)).format("YYYYMMDD"));
			vevent.addProperty("DTEND;VALUE=DATE",moment(new Date(doc.end)).format("YYYYMMDD"));
		else
			vevent.addProperty("DTSTART;TZID=Asia/Shanghai",moment(new Date(doc.start)).format("YYYYMMDDTHHmmss"));#TZID得改
			vevent.addProperty("DTEND;TZID=Asia/Shanghai",moment(new Date(doc.end)).format("YYYYMMDDTHHmmss"));
		vevent.addProperty("SEQUENCE",0);#得改
		calendardata = ical.toString();
		return calendardata
	
	addCalendarObjects:(userId, doc,operation)->
		myDate = new Date();
		doc.lastmodified = parseInt(myDate.getTime()/1000);
		myDate = new Date(doc.start)
		doc.firstoccurence = parseInt(myDate.getTime()/1000);
		myDate = new Date (doc.end)
		doc.lastoccurence = parseInt(myDate.getTime()/1000);
		doc.calendardata = Calendar.addEvent(userId,doc,operation);
		doc.etag = MD5(doc.calendardata);
		doc.size = doc.calendardata.length;
		color = Calendars.findOne({_id:doc.calendarid}).color;
		if doc.start > doc.end
			throw new Meteor.Error(400, "开始时间不能大于结束时间");
		doc.eventcolor =color;
		doc.parentId=doc._id;
		return doc
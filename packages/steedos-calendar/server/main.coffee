import { Meteor } from 'meteor/meteor';
icalendar = require('icalendar');
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
		zones=moment_timezone.tz.zone(doc.timezone);
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
	
	members_Attendee :(userId, doc)->
		attendees=[]
		for member,i in doc.members
			steedosId=Meteor.users.findOne({_id:member}).steedos_id
			doc.attendees=["REQ-PARTICIPANT","INDIVIDUAL","NEEDS-ACTION",steedosId,steedosId]
			if member!= userId
				doc.attendees[2]="ACCEPTED"
			attendees.push  
				CUTYPE:doc.attendees[1],
				ROLE:doc.attendees[0],
				CN:doc.attendees[3],
				PARTSTAT:doc.attendees[2],
				mailto:doc.attendees[4]
		return attendees	
	#新建或跟更新事件，事件对应的calendardata
	addEvent :(userId, doc)->
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
		attendees=Calendar.members_Attendee(userId,doc);
		for attendee,i in attendees
			attendee=attendees[i]
			attendee_string="ATTENDEES;"+"CUTYPE="+attendee[1]+";ROLE="+attendee[0]+";CN="+attendee[3]+";PARTSTAT="+attendee[2]+";mailto:"
			vevent.addProperty(attendee_string, attendee[4]);
		if doc.allDay==true
			vevent.addProperty("DTSTART;VALUE=DATE",moment(new Date(doc.start)).format("YYYYMMDD"));
			vevent.addProperty("DTEND;VALUE=DATE",moment(new Date(doc.end)).format("YYYYMMDD"));
		else
			vevent.addProperty("DTSTART;TZID=Asia/Shanghai",moment(new Date(doc.start)).format("YYYYMMDDTHHmmss"));#TZID得改
			vevent.addProperty("DTEND;TZID=Asia/Shanghai",moment(new Date(doc.end)).format("YYYYMMDDTHHmmss"));
		vevent.addProperty("SEQUENCE",0);#得改
		calendardata = ical.toString();
		return calendardata
	
	


import { Meteor } from 'meteor/meteor';
icalendar = require('icalendar');
Meteor.startup ->
	
@Calendar = 
	addChange : (calendarId,startToken,tokenCount, objectUri, operation)->
		#oldsynctoken = Calendars.findOne({_id:calendarId}).synctoken;
		i = 1
		while i <= tokenCount
			calendarchanges.insert
					uri:objectUri,
					synctoken: startToken+i,
					calendarid: calendarId,
					operation: operation
			i++		
		Calendars.direct.update({_id:calendarId},{$set:{synctoken:startToken+tokenCount}});
	
	addInstance : (userId,doc,calendarid,steedosId,access,herf,displayname)->
		if doc.visibility == 'private'
			transp = false;
		else
			transp = true;
		calendarinstances.insert
			principaluri:"principals/" + steedosId,
			transparent:transp,
			access:access,
			share_invitestatus:4,
			calendarid: calendarid,
			displayname:doc.title,
			description:"null",
			timezone:"Shanghai",
			calendarorder:3,
			calendarcolor: doc.color,
			share_herf:herf,
			share_displayname: displayname
	addEvent :(userId, doc,created)->
		ical = new icalendar.iCalendar();
		vevent = new icalendar.VEvent(doc._id);
		vtimezone=ical.addComponent('VTIMEZONE');
		ical.addComponent(vevent);
		vtimezone.addProperty("TZID","Asia/Shanghai");
		standard = vtimezone.addComponent("STANDARD");
		standard.addProperty("TZOFFSETFROM","0800");
		standard.addProperty("TZOFFSETTO","0800");
		standard.addProperty("TZNAME","CST");
		if doc.alarms !=undefined
			alarm = vevent.addComponent('VALARM');
			alarm.addProperty("ACTION", 'DISPLAY');
			alarm.addProperty("TRIGGER;VALUE = DURATION", doc.alarms);
		vevent.setDescription(doc.description);
		vevent.addProperty("TRANSP","OPAQUE");#得改
		vevent.addProperty("CREATED",created);
		vevent.addProperty("LAST-MODIFIED",new Date());
		#vevent.addProperty("DTSTAMP",new Date());
		vevent.setSummary(doc.title);
		vevent.addProperty("ORGANIZER;RSVP=TRUE;PARTSTAT=ACCEPTED;ROLE=CHAIR:mailto",Meteor.users.findOne({_id:userId}).steedos_id);
		#vevent.addProperty("UID",doc._id);
		vevent.setLocation("Shanghai");
		for member,i in doc.members 
			member = doc.members[i]
			if member!= userId
				vevent.addProperty("ATTENDEE;RSVP=TRUE;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;SCHEDULE-STATUS=3.7", Meteor.users.findOne({_id:member}).steedos_id);
		if doc.allDay==true
			vevent.addProperty("DTSTART;VALUE=DATE",moment(new Date(doc.start)).format("YYYYMMDD"));
			vevent.addProperty("DTEND;VALUE=DATE",moment(new Date(doc.end)).format("YYYYMMDD"));
		else
			vevent.addProperty("DTSTART;TZID=Asia/Shanghai",moment(new Date(doc.start)).format("YYYYMMDDThhmmss"));#TZID得改
			vevent.addProperty("DTEND;TZID=Asia/Shanghai",moment(new Date(doc.end)).format("YYYYMMDDThhmmss"));
		vevent.addProperty("SEQUENCE",3);#得改
		calendardata = ical.toString();
		return calendardata
		
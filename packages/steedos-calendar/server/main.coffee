import { Meteor } from 'meteor/meteor';
icalendar = require('icalendar');
MD5 = require('MD5');
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
	addInstance : (memberid,doc,calendarid,steedosId,access,herf,displayname)->
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
		daylight = vtimezone.addComponent("DAYLIGHT");
		daylight.addProperty("TZOFFSETFROM","0800");
		daylight.addProperty("TZNAME","GMT+8");
		daylight.addProperty("TZOFFSETTO","0900");
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
			checked:true,
			principalid:memberid,
			share_herf:herf,
			share_displayname: displayname	

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
			doc.alarms.forEach (alarm)->
				Alarm = vevent.addComponent('VALARM');
				Alarm.addProperty("ACTION", 'DISPLAY');
				Alarm.addProperty("TRIGGER;VALUE=DURATION", alarm);
				Alarm.addProperty("DESCRIPTION","Default Mozilla Description"); 
		vevent.setDescription(doc.description);
		vevent.addProperty("TRANSP","OPAQUE");#得改
		vevent.addProperty("CREATED",new Date());
		vevent.addProperty("LAST-MODIFIED",new Date());
		vevent.setSummary(doc.title);
		vevent.addProperty("ORGANIZER;RSVP=TRUE;PARTSTAT=ACCEPTED;ROLE=CHAIR:mailto",Meteor.users.findOne({_id:userId}).steedos_id);
		vevent.setLocation("Shanghai"); 
		doc.attendees.forEach (attendee)->
			attendee_string="ATTENDEE;"+"CUTYPE="+attendee.cutype+";ROLE="+attendee.role+";CN="+attendee.cn+";PARTSTAT="+attendee.partstat+":mailto"
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
	#重写object
	#operation: 1新建，2更新，3删除
	addCalendarObjects:(userId, doc,operation)->
		myDate = new Date();
		doc.lastmodified = parseInt(myDate.getTime()/1000);
		myDate = new Date(doc.start)
		doc.firstoccurence = parseInt(myDate.getTime()/1000);
		myDate = new Date (doc.end)
		doc.lastoccurence = parseInt(myDate.getTime()/1000);
		doc.calendardata = Calendar.addEvent(userId,doc);
		doc.etag = MD5(doc.calendardata);
		doc.size = doc.calendardata.length;
		color = Calendars.findOne({_id:doc.calendarid}).color;
		if doc.start > doc.end
			throw new Meteor.Error(400, "开始时间不能大于结束时间");
		doc.eventcolor =color;
		if operation==1
			doc.parentId=doc._id;
		return doc
	
	bytesToUuid:(buf, offset)->
		byteToHex = [];
		j=0;
		while j<256 
			byteToHex[j] = (j + 0x100).toString(16).substr(1);
			++j
		i = offset || 0;
		bth = byteToHex;
		return 	bth[buf[i++]] + bth[buf[i++]] +
				bth[buf[i++]] + bth[buf[i++]] + '-' +
				bth[buf[i++]] + bth[buf[i++]] + '-' +
				bth[buf[i++]] + bth[buf[i++]] + '-' +
				bth[buf[i++]] + bth[buf[i++]] + '-' +
				bth[buf[i++]] + bth[buf[i++]] +
				bth[buf[i++]] + bth[buf[i++]] +
				bth[buf[i++]] + bth[buf[i++]]

	rng:()->
		rb = require('crypto').randomBytes;
		return rb(16);

	uuid:(options, buf, offset)->
		i = buf && offset || 0;
		if typeof options == 'string'
  			buf = if options == 'binary' then new Array(16) else null
  			options = null
		options = options || {};
		rnds = options.random || Calendar.rng();
		rnds[6] = (rnds[6] & 0x0f) | 0x40;
		rnds[8] = (rnds[8] & 0x3f) | 0x80;
		if (buf)
			ii=0;
			while ii<16
				buf[i + ii] = rnds[ii]
				++ii
		return buf || Calendar.bytesToUuid(rnds);

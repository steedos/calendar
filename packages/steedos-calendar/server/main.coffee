import { Meteor } from 'meteor/meteor';
import moment from 'moment'
icalendar = require('icalendar');
MD5 = require('MD5');
ICAL = require('ical.js');
moment_timezone = require('moment-timezone');
Meteor.startup ->
	
Calendar = 
	#更新日历，新建事件，更新事件，删除事件会触发此函数。operation:1新建，2更新，3删除
	isLegalVersion : (spaceId,app_version)->
		if !spaceId
			return false
		check = false
		modules = db.spaces.findOne(spaceId)?.modules
		if modules and modules.includes(app_version)
			check = true
		return check
	addChange : (calendarId, objectUri, operation)->
		userSpaces = db.space_users.find({user: Meteor.userId()},{field:{space:1}}).fetch()
		userSpacesId =_.pluck(userSpaces,'space')
		i=0
		console.log userSpacesId.length
		while i<userSpacesId.length
			if Calendar.isLegalVersion(userSpacesId[i],"calendar.professional")
				console.log "11111===="
				oldsynctoken = Calendars.findOne({_id:calendarId}).synctoken;
				calendarchanges.direct.insert
					uri:objectUri,
					synctoken: oldsynctoken,
					calendarid: calendarId,
					operation: operation
				Calendars.direct.update({_id:calendarId},{$set:{synctoken:oldsynctoken+1}});
				break
			console.log Calendar.isLegalVersion(userSpacesId[i],"calendar.professional")
			i++
	#被分享的成员比创建者多share_herf,share_displayname. 
	#access对应 1 = owner, 2 = readonly, 3 = readwrite
	addInstance : (memberid,doc,calendarid,steedosId,access,herf,displayname)->
		if doc.visibility == 'private'
			transp = false;
		else
			transp = true;
		zones=moment_timezone.tz.zone(doc.timezone);
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
			share_herf:herf,
			share_displayname: displayname	

	#新建或跟更新事件，事件对应的calendardata
	addEvent :(userId, doc)->
		ical = new icalendar.iCalendar();
		vevent = new icalendar.VEvent(doc.uid);
		timezone=Calendars.findOne({_id:doc.calendarid}).timezone;
		zones=moment_timezone.tz.zone(timezone);
		zone_name = zones.name
		vtimezone=ical.addComponent('VTIMEZONE');
		ical.addComponent(vevent);
		vtimezone.addProperty("TZID",zone_name);
		standard = vtimezone.addComponent("STANDARD");
		standard.addProperty("TZOFFSETFROM","0"+(-zones.offsets[1])/60+"00");
		standard.addProperty("RRULE","FREQ=YEARLY;UNTIL=19910914T150000Z;BYMONTH=9;BYDAY=3SU")
		standard.addProperty("TZOFFSETTO","0"+(-zones.offsets[0])/60+"00");
		standard.addProperty("TZNAME","GMT+8");
		standard.addProperty("DTSTART",new Date("1989-09-17T00:00:00"));
		#standard.addProperty("RDATE",new Date("1901-01-01T08:00:00"));
		daylight = vtimezone.addComponent("DAYLIGHT");
		daylight.addProperty("TZOFFSETFROM","0"+(-zones.offsets[0])/60+"00");
		daylight.addProperty("DTSTART",new Date("1991-04-14T08:00:00"));
		daylight.addProperty("TZNAME","GMT+8");
		daylight.addProperty("TZOFFSETTO","0"+(-zones.offsets[1])/60+"00");
		daylight.addProperty("RDATE",new Date("1991-04-14T08:00:00"));
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
		vevent.addProperty("ORGANIZER;RSVP=TRUE;PARTSTAT=ACCEPTED;ROLE=CHAIR:mailto",Meteor.users.findOne({_id:userId},{field:{steedos_id:1}})?.steedos_id);
		vevent.setLocation(doc?.site); 
		doc?.attendees?.forEach (attendee)->
			attendee_string="ATTENDEE;"+"CUTYPE="+attendee.cutype+";ROLE="+attendee.role+";CN="+attendee.cn+";PARTSTAT="+attendee.partstat+":mailto"
			vevent.addProperty(attendee_string, attendee.mailto)
		if doc?.allDay==true
			vevent.addProperty("DTSTART;VALUE=DATE",moment(new Date(doc.start)).tz(zone_name).format("YYYYMMDD"));
			vevent.addProperty("DTEND;VALUE=DATE",moment(new Date(doc.end)).tz(zone_name).format("YYYYMMDD"));
		else
			vevent.addProperty("DTSTART;TZID=#{zone_name}",moment(new Date(doc.start)).tz(zone_name).format("YYYYMMDDTHHmmss"));#TZID得改
			vevent.addProperty("DTEND;TZID=#{zone_name}",moment(new Date(doc.end)).tz(zone_name).format("YYYYMMDDTHHmmss"));
		vevent?.addProperty("SEQUENCE",0);#得改
		calendardata = ical.toString();
		return calendardata
	#重写object
	#operation: 1新建，2更新，3删除
	addCalendarObjects:(userId, doc,operation)->
		if doc.start > doc.end
			throw new Meteor.Error(400, "start_time_must_be_less_than_end_time");
		doc.remindtimes=Calendar.remindtimes(doc.alarms,doc.start)
		if !doc.Isdavmodified
			myDate = new Date();
			doc.lastmodified = parseInt(myDate.getTime()/1000);
			myDate = new Date(doc.start)
			doc.firstoccurence = parseInt(myDate.getTime()/1000);
			myDate = new Date (doc.end)
			doc.lastoccurence = parseInt(myDate.getTime()/1000);
			doc.calendardata = Calendar.addEvent(userId,doc);
			doc.etag = MD5(doc.calendardata);
			doc.size = doc.calendardata.length;
			# color = Calendars.findOne({_id:doc.calendarid}).color;
			# doc.eventcolor =color;
			if operation==1
				doc.parentId=doc._id;
		return doc
	remindtimes:(alarms,start)->
		remindtimes=[]
		if alarms
			alarms.forEach (alarm)->
				miliseconds=0
				if alarm[2]=='T'
					if alarm[alarm.length-1]=='M'
						i=3 
						mimutes=0
						while i<alarm.length-1
							mimutes=mimutes+alarm[i]*(Math.pow(10,alarm.length-2-i))
							i++
						miliseconds=mimutes*60*1000
						remindtime=moment(start).utc().valueOf()-miliseconds
					else if alarm[alarm.length-1]=='S'
							remindtime=moment(start).utc().valueOf()
						else 
							i=3 
							hours=0
							while i<alarm.length-1
								hours=hours+alarm[i]*(Math.pow(10,alarm.length-2-i))
								i++
							miliseconds=hours*60*60*1000
							remindtime=moment(start).utc().valueOf()-miliseconds
				else
					i=2
					days=0
					while i<alarm.length-1
						days=days+alarm[i]*(Math.pow(10,alarm.length-2-i))
						i++
					miliseconds=days*24*60*60*1000
					remindtime=moment(start).utc().valueOf()-miliseconds
				remindtimes.push remindtime
		return remindtimes
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

export { Calendar }
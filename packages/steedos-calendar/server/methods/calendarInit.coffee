Meteor.methods
	calendarInit: (userId,timezone) ->
		if Calendars.find({"ownerId":userId},{"isDefault":true}).count()==0
			name=Meteor.users.findOne({_id:userId}).name
			doc =
				title:name+"的日历",
				members:[userId],
				visibility:"private",
				color:CALENDARCOLORS[parseInt(10000*Math.random())%24],
				ownerId:userId,
				timezone:timezone,
				isDefault:true,
				components:["VEVENT","VTODO"],
				synctoken:1
			Meteor.call('calendarinsert',doc);
			#doc=Calendars.find({"ownerId":userId},{"isDefault":true})
			 #steedosId = Meteor.users.findOne({_id:userId}).steedos_id;
			#Calendar.addInstance(userId,doc,doc._id,steedosId,1,"","");

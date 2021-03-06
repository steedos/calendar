Meteor.methods
	calendarInit: (userId,timezone) ->
		
		if Calendars.find({"ownerId":userId,"isDefault":true}).count()==0
			name=Meteor.users.findOne({_id:userId},{field:{name:1}})?.name
			if !name
				name="未命名"
			doc =
				title:name,
				members:[userId],
				admins:[userId],
				visibility:"private",
				color:CALENDARCOLORS[parseInt(10000*Math.random())%7],
				ownerId:userId,
				timezone:timezone,
				isDefault:true,
				components:["VEVENT","VTODO"],
				synctoken:1
			Meteor.call('calendarinsert',doc);
			#doc=Calendars.find({"ownerId":userId},{"isDefault":true})
			 #steedosId = Meteor.users.findOne({_id:userId}).steedos_id;
			#Calendar.addInstance(userId,doc,doc._id,steedosId,1,"","");

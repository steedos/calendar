Meteor.methods
	calendarInit: (timezone) ->
		if Calendars.find({$or:[{"ownerId":this.userId},{"members":this.userId}]}).count()==0
			name=Meteor.users.findOne({_id:this.userId}).name
			Calendars.insert
				title:name+"的日历",
				members:[this.userId],
				visibility:"private",
				color:CALENDARCOLORS[parseInt(10000*Math.random())%24],
				ownerId:this.userId,
				timezone:timezone,
				Isdefaultcalendar:true,
				components:["VEVENT","VTODO"],
				synctoken:1

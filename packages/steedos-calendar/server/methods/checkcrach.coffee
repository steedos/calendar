Meteor.methods
	checkcrach: (obj) ->
		crachattendees=[]
		attendeesid=_.pluck(obj.attendees,'id');
		attendeesid.forEach (attendeeid)->
			events=Events.find({_id:{$ne:obj._id}}).fetch()
			events.forEach (event)->
				eventattendeesid=_.pluck(event.attendees,'id');
				if _.indexOf(eventattendeesid, attendeeid)!=-1
					if (obj.start<event.start and obj.end>event.end) or (obj.start>event.start and obj.start<event.end) or 
					(obj.end>event.start and obj.end<event.end) or (obj.start>event.start and obj.end<event.end)
						name=Meteor.users.findOne({_id:attendeeid}).name
						if _.indexOf(crachattendees, name)==-1
							crachattendees.push name
		errorstring=''
		crachattendees.forEach (crachattendee)->
			errorstring=errorstring+crachattendee+"有时间冲突"
		if errorstring!=''
			throw new Meteor.Error(400, errorstring);

					



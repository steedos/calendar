Meteor.methods
	selectGetUsers: (options) ->
		this.unblock();
		searchText = options.searchText;
		values = options.values;
		console.log(options)
		users = []
		if (searchText)
			users = Meteor.users.find({username: {$regex: searchText}}, {limit: 5}).fetch();
		else if (values.length) 
			users = Meteor.users.find({_id: {$in: values}}).fetch();	
		users = Meteor.users.find({}, {limit: 5}).fetch();
		
		results = []
		_.each users, (user)->
			if user.profile?.name
				label = user.profile.name
			else if user.username
				label = user.username
			else
				label = user._id

			if user.emails[0].address?
				label = label + "(" + user.emails[0].address + ")"
				
			results.push
				label: label
				value: user._id
 
		return results	
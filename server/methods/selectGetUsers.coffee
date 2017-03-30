Meteor.methods
	selectGetUsers: (options) ->
		this.unblock();
		searchText = options.searchText;
		values = options.values;
		users = []
		if (searchText)
			users = Meteor.users.find(
				{
					$or: [
						{"username": {$regex: searchText}},
						{"name": {$regex: searchText}},
						{"emails.address": {$regex: searchText}}
					]
				}, 
				{limit: 10}
			).fetch()
		else if (values.length) 
			users = Meteor.users.find({_id: {$in: values}}).fetch();	
		else
			return []

		results = []
		_.each users, (user)->
			if user.name
				label = user.name
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
Meteor.methods
	selectGetUsers: (options) ->
		this.unblock();
		searchText = options.searchText;
		values = options.values;
		users = []

		space_users = db.space_users.find({user: this.userId})

		spaces = []

		space_users.forEach (su)->
			spaces.push su.space

		#		if (searchText?.length>1)
		#			users = Meteor.users.find({ $or: [
		#				{ 'name': searchText }
		#				{ 'emails.address': searchText }
		#			],space: {$in: spaces} }, limit: 10).fetch()
		#		else if (values.length)
		#			users = Meteor.users.find({_id: {$in: values}}).fetch();
		#		else
		#			return []

		if (searchText?.length > 1)
			users = db.space_users.find({
				$or: [
					{'name': searchText}
					{'email': searchText}
					{'mobile': searchText}
				], space: {$in: spaces}
			}, limit: 10).fetch()
		else if (values.length)
			users = db.space_users.find({user: {$in: values}}).fetch();
		else
			return []

		results = []

		keys = []

		_.each users, (user)->
			if user.name
				label = user.name
			else if user.username
				label = user.username
			else
				label = user.user

			if user.email
				label = label + "(" + user.email + ")"

			if keys.indexOf(user.user) < 0
				results.push
					label: label
					value: user.user

				keys.push user.user


		#			results = _.uniq(results, 'value')

		#			console.log results

		return results	
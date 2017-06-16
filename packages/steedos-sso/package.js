Package.describe({
	name: 'steedos:sso',
	version: '0.0.1',
	summary: 'Login to meteor apps with parameter or cookies',
	git: ''
});

Package.onUse(function(api) {
	api.use('kadira:flow-router@2.10.1');
	api.use('coffeescript');

	api.addFiles('client/steedos_login.coffee', 'client');
	api.addFiles('client/token_login.coffee', 'client');
});
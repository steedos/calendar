@Calendar = {}


Meteor.startup ->
	Steedos.API.setAppTitle("Steedos Calendar");
	$("body").css("background-image", "url('/packages/steedos_theme/client/background/birds.jpg')");
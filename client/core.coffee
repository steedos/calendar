import 'sweetalert/dist/sweetalert-dev.js'
import 'sweetalert/dist/sweetalert.css'
@Calendar = {}

Meteor.startup ->
	Steedos.API.setAppTitle("Steedos Calendar");
	$("body").css("background-image", "url('/packages/steedos_theme/client/background/birds.jpg')");
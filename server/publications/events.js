Meteor.publish("calendar_events", function() {

  return Events.find({});
  
});

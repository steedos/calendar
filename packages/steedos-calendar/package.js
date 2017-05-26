Package.describe({
    name: 'steedos:calendar',
    version: '0.0.2_4',
    summary: 'Steedos calendar system',
    git: ''
});

Npm.depends({
    'icalendar':'0.7.1',
    'MD5':'1.3.0',
    'moment-timezone':'0.5.13',
    'uuid':'3.0.1'
});

Package.onUse(function(api) {
    api.versionsFrom('1.0');

    api.use('ecmascript@0.6.3');

    api.use('reactive-var@1.0.10');
    api.use('reactive-dict@1.1.8');
    api.use('coffeescript@1.11.1_4');
    api.use('random@1.0.10');
    api.use('ddp@1.2.5');
    api.use('check@1.2.3');
    api.use('ddp-rate-limiter@1.0.5');
    api.use('underscore@1.0.10');
    api.use('tracker@1.1.0');
    api.use('session@1.1.6');
    api.use('blaze@2.1.9');
    api.use('templating@1.2.15');
    api.use('flemay:less-autoprefixer@1.2.0');
    api.use('simple:json-routes@2.1.0');
    api.use('nimble:restivus@0.8.7');
    api.use('aldeed:simple-schema@1.3.3');
    api.use('aldeed:collection2@2.5.0');
    api.use('aldeed:tabular@1.6.1');
    api.use('aldeed:autoform@5.8.0');
    api.use('matb33:collection-hooks@0.8.1');
  
    api.use('kadira:blaze-layout@2.3.0');
    api.use('kadira:flow-router@2.10.1');

    api.use('aldeed:autoform-bs-datetimepicker@1.0.6');
    api.use('hausor:autoform-bs-minicolors@1.0.0');

    api.use('meteorhacks:ssr@2.2.0');
    api.use('tap:i18n@1.7.0');
    api.use('meteorhacks:subs-manager@1.6.4');

    api.use(['webapp@1.3.11'], 'server');

    api.use('momentjs:moment@2.14.1', 'client');
   

    api.use('steedos:adminlte@2.3.12_3');
    api.use('steedos:base@0.0.14');
    api.use('steedos:theme@0.0.11');
    api.use('simple:json-routes@2.1.0');

    api.use('rzymek:fullcalendar@3.4.0');
    api.use('steedos:calendar-i18n@0.0.2_4');

    api.use('steedos:autoform-modals@0.3.9_4');
    api.use('steedos:universe-autoform-select@0.3.10');

    api.addFiles('client/event/event.html', 'client');
    api.addFiles('client/event/event.coffee', 'client');
    api.addFiles('client/event/event.less', 'client');

    api.addFiles('client/event/event_detail.html', 'client');
    api.addFiles('client/event/event_detail.coffee', 'client');
    api.addFiles('client/event/event_detail.less', 'client');




    api.addFiles('client/layout/layout.html', 'client');
    api.addFiles('client/layout/layout.less', 'client');
    api.addFiles('client/layout/sidebar.html', 'client');
    api.addFiles('client/layout/sidebar.coffee', 'client');
    api.addFiles('client/layout/sidebar.less', 'client');

    api.addFiles('client/core.coffee', 'client');
    api.addFiles('client/local.coffee', 'client');
    api.addFiles('client/router.coffee', 'client');
    api.addFiles('client/subscribe.coffee', 'client');

    api.addFiles('models/calendarchanges.coffee');
    api.addFiles('models/calendarinstances.coffee');
    api.addFiles('models/calendars.coffee');
    api.addFiles('models/events.coffee');

    // api.addFiles('lib/attendees.coffee');

    api.addFiles('server/methods/calendarInit.coffee','server');
    api.addFiles('server/methods/calendarinsert.coffee','server');
    api.addFiles('server/methods/selectGetUsers.coffee','server');
    api.addFiles('server/methods/updateAttendees.coffee','server');
    api.addFiles('server/methods/removeEvents.coffee','server');
    api.addFiles('server/methods/attendeesInit.coffee','server');
    api.addFiles('server/publications/calendars.coffee','server');
    api.addFiles('server/publications/events.coffee','server');

    api.addFiles('server/main.coffee','server');

});
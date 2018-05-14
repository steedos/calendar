Package.describe({
    name: 'steedos:calendar',
    version: '0.1.26',
    summary: 'Steedos calendar system',
    git: ''
});

Npm.depends({
    'icalendar': '0.7.1',
    'ical.js': '1.2.2',
    'MD5': '1.3.0',
    'moment-timezone': '0.5.13'
});

Package.onUse(function(api) {
    api.versionsFrom('1.0');

    api.use('ecmascript@0.6.3');
    api.use('steedos:smsqueue@0.0.1');
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

    api.use('steedos:autoform-bs-datetimepicker@1.0.6');
    api.use('steedos:autoform-bs-minicolors@1.0.0');

    api.use('meteorhacks:ssr@2.2.0');
    api.use('tap:i18n@1.7.0');
    api.use('meteorhacks:subs-manager@1.6.4');

    api.use(['webapp@1.3.11'], 'server');

    api.use('momentjs:moment@2.14.1', 'client');


    api.use('es5-shim@4.6.15');
    // api.use('tsega:bootstrap3-datetimepicker@=3.1.3_3');
    api.use('simple:json-routes@2.1.0');
    api.use('steedos:fullcalendar@3.4.0_3');
    api.use('vazco:universe-selectize@0.1.22');

    api.use('steedos:sso@0.0.4')
    api.use('steedos:adminlte@2.3.12_3');
    api.use('steedos:base@0.0.65');
    api.use('steedos:accounts@0.0.24');
    api.use('steedos:theme@0.0.29');
    api.use('steedos:i18n@0.0.11');
    api.use('steedos:calendar-i18n@0.0.16');
    api.use('steedos:autoform@0.0.7');
    api.use('steedos:autoform-modals@0.3.9_6');
    api.use('raix:push@3.0.2');

    api.addFiles('client/event/event.html', 'client');
    api.addFiles('client/event/event.coffee', 'client');
    api.addFiles('client/event/event.less', 'client');

    api.addFiles('client/event/event_detail.html', 'client');
    api.addFiles('client/event/event_detail.coffee', 'client');
    api.addFiles('client/event/event_detail.less', 'client');
    api.addFiles('client/event/event_pending.html', 'client');
    api.addFiles('client/event/event_pending.coffee', 'client');
    api.addFiles('client/event/event_pending.less', 'client');



    api.addFiles('client/layout/layout.html', 'client');
    api.addFiles('client/layout/layout.less', 'client');
    api.addFiles('client/layout/layout.coffee', 'client');
    api.addFiles('client/layout/sidebar.html', 'client');
    api.addFiles('client/layout/sidebar.coffee', 'client');
    api.addFiles('client/layout/sidebar.less', 'client');
    api.addFiles('client/layout/subcalendar.html', 'client');
    api.addFiles('client/layout/subcalendar.coffee', 'client');
    api.addFiles('client/layout/subcalendar.less', 'client');
    api.addFiles('client/layout/members_busy_pending.html', 'client');
    api.addFiles('client/layout/members_busy_pending.coffee', 'client');
    api.addFiles('client/layout/members_busy_pending.less', 'client');
    api.addAssets('client/layout/print.css', 'client');

    api.addFiles('client/core.coffee', 'client');
    api.addFiles('client/router.coffee', 'client');
    api.addFiles('client/subscribe.coffee', 'client');

    api.addFiles('models/calendarchanges.coffee');
    api.addFiles('models/calendarinstances.coffee');
    api.addFiles('models/calendars.coffee');
    api.addFiles('models/events.coffee');
    api.addFiles('models/calendarsubscriptions.coffee');
    api.addFiles('models/tabular.coffee');

    // api.addFiles('lib/attendees.coffee');

    api.addFiles('server/methods/calendarInit.coffee', 'server');
    api.addFiles('server/methods/calendarinsert.coffee', 'server');
    api.addFiles('server/methods/selectGetUsers.coffee', 'server');
    api.addFiles('server/methods/updateEvents.coffee', 'server');
    api.addFiles('server/methods/removeEvents.coffee', 'server');
    api.addFiles('server/methods/attendeesInit.coffee', 'server');
    api.addFiles('server/methods/updateinstances.coffee', 'server');
    api.addFiles('server/methods/eventInit.coffee', 'server');
    api.addFiles('server/methods/davModifiedEvent.coffee', 'server');
    api.addFiles('server/methods/alarmPush.coffee', 'server');
    api.addFiles('server/methods/subCalendar.coffee', 'server');
    api.addFiles('server/methods/shareCalendar.coffee', 'server');
    api.addFiles('server/methods/removeSubCalendars.coffee', 'server');
    // api.addFiles('server/methods/checkcrach.coffee','server');
    api.addFiles('server/methods/initscription.coffee', 'server');
    api.addFiles('server/methods/addCalendarObjects.coffee', 'server');
    api.addFiles('server/methods/addMembersBusy.coffee', 'server');
    api.addFiles('server/methods/updateSubcalendar.coffee', 'server');
    api.addFiles('server/methods/updateMembersBusy.coffee', 'server');
    api.addFiles('server/methods/eventNotification.coffee', 'server');
    api.addFiles('server/publications/calendars.coffee', 'server');
    api.addFiles('server/publications/events.coffee', 'server');
    api.addFiles('server/publications/subcalendars.coffee', 'server');
    api.addFiles('server/publications/calendarinstances.coffee', 'server');
    api.addFiles('server/publications/reminders.coffee', 'server');
    api.addFiles('server/publications/event_need_action.coffee', 'server');
    api.addFiles('server/main.coffee', 'server');

    api.addFiles('server/routes/api_calendar_events.coffee', 'server');

});
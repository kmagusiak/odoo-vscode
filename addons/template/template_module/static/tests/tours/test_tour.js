/** @odoo-module */
import tour from 'web_tour.tour';
tour.register('template_tour', {
    url: "/web",
    test: true,
}, [
    // tour.stepUtils.showAppsMenuItem(),
    ...tour.stepUtils.goToAppSteps('base.menu_management', 'Open apps'),
    {
        content: "Find something",
        trigger: 'a',
        run: function() {},  // do nothing
    },
]);

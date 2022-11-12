odoo.define('sale.tour', function(require) {
    "use strict";

    const {_t} = require('web.core');
    var tour = require('web_tour.tour');

    tour.register('template_tour', {
        url: '/web',  // Here, you can specify any other starting url
        test: true,
    }, [
        tour.stepUtils.showAppsMenuItem(),
        {
            trigger: ".o_app[data-menu-xmlid='base.menu_management']",
            content: _t("Open Apps"),
        },
    ]);
});

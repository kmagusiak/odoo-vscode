# https://www.odoo.com/documentation/16.0/developer/reference/backend/testing.html#writing-a-test-tour
from odoo.tests.common import HttpCase, tagged


@tagged('-at_install', '-standard', 'post_install', 'tour')
class IntegrationCase(HttpCase):
    def test_tour(self):
        """Default create"""
        self.start_tour("/web", 'template_module.test_tour', login="admin")

# https://www.odoo.com/documentation/master/developer/reference/backend/testing.html#writing-a-test-tour
from odoo.tests.common import HttpCase, tagged


@tagged('-at_install', '-standard', 'post_install', 'tour')
class IntegrationCase(HttpCase):
    def test_tour(self):
        """Default create"""
        # add watch=True for debugging
        self.start_tour("/web", 'template_tour', login="admin")

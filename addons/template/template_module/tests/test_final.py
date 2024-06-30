# https://www.odoo.com/documentation/master/developer/reference/backend/testing.html
from odoo.tests.common import TransactionCase, tagged


# Run test after all modules are installed
@tagged('-at_install', 'post_install')
class ExampleFinalCase(TransactionCase):
    def test_create_final(self):
        """Default create"""
        obj = self.env['template.template'].create({'name': 'test'})
        self.assertEqual(len(obj), 1)

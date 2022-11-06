# https://www.odoo.com/documentation/16.0/developer/reference/backend/testing.html
from odoo.tests.common import TransactionCase


class ExampleCase(TransactionCase):
    def test_create(self):
        """Default create"""
        obj = self.env['template.template'].create({'name': 'test'})
        self.assertEqual(len(obj), 1)

# https://www.odoo.com/documentation/15.0/fr/developer/reference/backend/testing.html#testing-python-code
from odoo.tests.common import TransactionCase


class ExampleCase(TransactionCase):
    def test_create(self):
        """Default create"""
        obj = self.env['template.template'].create({'name': 'test'})
        self.assertEqual(len(obj), 1)

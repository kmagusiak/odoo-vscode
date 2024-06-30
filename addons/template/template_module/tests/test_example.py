# https://www.odoo.com/documentation/master/developer/reference/backend/testing.html
from odoo.tests.common import Form, TransactionCase


class ExampleCase(TransactionCase):
    def test_create(self):
        """Default create"""
        obj = self.env['template.template'].create({'name': 'test'})
        self.assertEqual(len(obj), 1)

    def test_form(self):
        f = Form(self.env['template.template'])
        f.name = 'abc'
        self.assertEqual(f.hello, "Hello abc")
        f.save()

from odoo import api, fields, models


class Template(models.Model):
    _name = 'template.template'
    _description = 'template.template'

    name = fields.Char()
    hello = fields.Char(compute='_compute_hello')

    @api.depends('name')
    def _compute_hello(self):
        for r in self:
            r.hello = "Hello %s" % r.name

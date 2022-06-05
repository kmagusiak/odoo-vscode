from odoo import fields, models


class Template(models.Model):
    _name = 'template.template'
    _description = 'template.template'

    name = fields.Char()

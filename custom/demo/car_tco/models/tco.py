from odoo import api, fields, models


class CarTCO(models.Model):
    _name = "car.tco"
    _description = "Car TCO"

    name = fields.Char()

    power = fields.Integer()
    weight = fields.Integer()

    power_ratio = fields.Float(compute="_compute_car_data")

    @api.depends('power', 'weight')
    def _compute_car_data(self):
        for c in self:
            c.power_ratio = c.power / c.weight if c.weight else False

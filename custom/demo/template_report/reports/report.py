from odoo import fields, models, tools


class Report(models.Model):
    _name = "template.report"
    _description = "template.report"
    _auto = False

    name = fields.Char()

    def init(self):
        tools.drop_view_if_exists(self.env.cr, "template_report")
        self.env.cr.execute(
            """
        create or replace view template_report as (
            select i.id
                ,i.create_date
                ,i.create_uid
                ,i.write_date
                ,i.write_uid
                ,i.name
            from sale_order i
            where i.state = 'sale'
        )
            """
        )

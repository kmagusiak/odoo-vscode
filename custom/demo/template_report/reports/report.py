from odoo import fields, models, tools


class Report(models.Model):
    _name = "report.template.example"
    _description = "report.template.example"
    _auto = False

    name = fields.Char()

    def init(self):
        tools.drop_view_if_exists(self.env.cr, "report_template_example")
        self.env.cr.execute(
            """
        create or replace view report_template_example as (
            select i.id
                ,i.create_date
                ,i.create_uid
                ,i.write_date
                ,i.write_uid
                ,i.login as name
            from res_users i
        )
            """
        )

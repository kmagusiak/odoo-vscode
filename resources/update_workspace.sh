#!/bin/bash
rm -f /workspace/{odoo,odoo-enterprise}
ln -s /opt/odoo /workspace/odoo
[ ! -d "$$ODOO_ENTERPRISE" ] || ln -s $ODOO_ENTERPRISE /workspace/odoo-enterprise

from odoo:15 as base
env PYTHONUNBUFFERED 1
env ODOO_BASEPATH /opt/odoo

# Changes to run with a dynamic container
user root
run mv /etc/odoo/odoo.conf /etc/odoo/odoo.conf.example \
	&& mkdir "$ODOO_BASEPATH" \
	&& chown odoo:odoo /etc/odoo /var/lib/odoo "$ODOO_BASEPATH"
# Script to manage the installation and update and debugging
run pip3 install --no-cache click-odoo-contrib debugpy

# Healthcheck and entrypoint
healthcheck CMD curl --fail http://127.0.0.1:8069/web_editor/static/src/xml/ace.xml || exit 1
copy --chown=odoo:odoo ./resources/entrypoint.sh /
copy --chown=odoo:odoo ./resources/getaddons.py /
entrypoint ["/entrypoint.sh"]
user odoo

# PRODUCTION
from base as production

# VSCODE (tools for development)
from base as vscode
user root
run apt-get update \
	&& apt-get -y install git htop \
	&& mkdir /mnt/vscode \
	&& chown odoo:odoo /mnt/vscode
user odoo

# DEBUG
from base as debug
expose 41234

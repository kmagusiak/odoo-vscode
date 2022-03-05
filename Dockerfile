from odoo:15
env PYTHONUNBUFFERED 1
env ODOO_BASEPATH /opt/odoo

# Changes to run with a dynamic container
user root
run mv /etc/odoo/odoo.conf /etc/odoo/odoo.conf.example \
	&& chown odoo:odoo /etc/odoo /var/lib/odoo
# TODO test this move
run mkdir "$ODOO_BASEPATH" && chown odoo:odoo "$ODOO_BASEPATH" \
	&& ln -s "/usr/bin/odoo" "$ODOO_BASEPATH/odoo-bin" \
	&& mv /usr/lib/python3/dist-packages/odoo "$ODOO_BASEPATH" \
	&& ln -s "$ODOO_BASEPATH/odoo" /usr/lib/python3/dist-packages/odoo
# Script to manage the installation and update and debugging
run pip3 install --no-cache click-odoo-contrib debugpy

# Healthcheck and entrypoint
healthcheck CMD curl --fail http://127.0.0.1:8069/web_editor/static/src/xml/ace.xml || exit 1
copy --chown=odoo:odoo ./resources/entrypoint.sh /
copy --chown=odoo:odoo ./resources/getaddons.py /
entrypoint ["/entrypoint.sh"]
expose 41234
user odoo

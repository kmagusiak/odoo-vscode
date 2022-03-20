from odoo:15 as base
env PYTHONUNBUFFERED 1
env ODOO_BASEPATH /opt/odoo

# Changes to run with a dynamic container
user root
run mv /etc/odoo/odoo.conf /etc/odoo/odoo.conf.example \
	&& mkdir -p "$ODOO_BASEPATH" \
	&& chown odoo:odoo /etc/odoo /var/lib/odoo "$ODOO_BASEPATH"
# Odoo forgot these icons...
run apt-get update \
	&& apt-get -y install fonts-glyphicons-halflings
# Move odoo package to $ODOO_BASEPATH
# (we must also update the links)
env PYTHON_DIST_PACKAGES=/usr/lib/python3/dist-packages
run for f in $(find "$PYTHON_DIST_PACKAGES/odoo" -type l); do ln -sf "$(readlink -f $f)" "$f"; done \
	&& mv "$PYTHON_DIST_PACKAGES/odoo" "$ODOO_BASEPATH" \
	&& echo "$ODOO_BASEPATH" > "$PYTHON_DIST_PACKAGES/odoo.pth" \
	&& cp /usr/bin/odoo "$ODOO_BASEPATH/odoo-bin"
# Script to manage the installation and update and debugging
run pip3 install --no-cache click-odoo-contrib debugpy

# Healthcheck and entrypoint
copy --chown=odoo:odoo ./resources/entrypoint.sh /
copy --chown=odoo:odoo ./resources/getaddons.py /
entrypoint ["/entrypoint.sh"]

# VSCODE (tools for development)
from base as vscode
user root
add requirements.txt /tmp
run apt-get update \
	&& apt-get -y install git htop less vim \
	&& pip3 install --no-cache invoke -r /tmp/requirements.txt \
	&& rm -f /tmp/requirements.txt
run useradd -G odoo --create-home vscode \
	&& mkdir /odoo-workspace \
	&& chown vscode:odoo /odoo-workspace
user odoo
volume ["/odoo-workspace"]

# PRODUCTION
from base as production
user odoo
healthcheck CMD curl --fail http://127.0.0.1:8069/web_editor/static/src/xml/ace.xml || exit 1

# DEBUG
from production as debug
expose 41234

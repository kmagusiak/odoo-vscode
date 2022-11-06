arg ODOO_VERSION=16.0
from ghcr.io/kmagusiak/odoo-docker:${ODOO_VERSION} as base

###############################
# DEV (tools for development)
from base as dev
user root
add requirements-dev.txt /tmp
run apt-get update \
	&& apt-get install -y --no-install-recommends git htop less openssh-client vim \
	&& apt-get install -y --no-install-recommends libxml2-utils \
	&& apt-get install -y --no-install-recommends chromium-driver \
	&& pip3 install --no-cache invoke -r /tmp/requirements-dev.txt \
	&& rm -f /tmp/requirements-dev.txt
# use a single user for both running the container and devcontainer
arg VSCODE_UID=1000
run useradd --uid "${VSCODE_UID}" -G odoo --create-home vscode \
	&& echo "root:${ODOO_PASSWORD:-admin}" | chpasswd
user vscode

###############################
# VSCODE
from dev as vscode
user root
run true \
	&& mkdir /odoo-workspace \
	&& chown vscode:odoo /odoo-workspace
user vscode

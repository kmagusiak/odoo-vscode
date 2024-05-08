arg ODOO_VERSION=16.0
arg DOCKER_BASE_IMAGE=base_image

# Base image with added development tools
from ghcr.io/kmagusiak/odoo-docker:${ODOO_VERSION} as base_image
user root
run apt-get update \
	&& apt-get install -y --no-install-recommends \
		bash-completion gettext git htop less openssh-client vim
# chrome for testing
run curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb --output /tmp/google-chrome.deb \
	&& apt-get install -y --no-install-recommends /tmp/google-chrome.deb \
	&& rm /tmp/google-chrome.deb

# Create the vscode development image
# python (dev) requirements
from ${DOCKER_BASE_IMAGE} as dev
add requirements-dev.txt /tmp
run cd /tmp \
	&& pip3 install --no-cache -r /tmp/requirements-dev.txt \
	&& rm -f /tmp/requirements-dev.txt

# use a single user for both running the container and devcontainer
from dev as vscode
arg DEV_UID=1000
run useradd --uid "${DEV_UID}" -G odoo --create-home vscode \
	&& echo "root:${ADMIN_PASSWORD:-admin}" | chpasswd \
	&& mkdir /odoo-workspace \
	&& chown vscode:odoo /odoo-workspace
user vscode

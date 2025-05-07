#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: emoscardini
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openziti/ziti

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing openziti"
mkdir -p --mode=0755 /usr/share/keyrings
curl -sSLf https://get.openziti.io/tun/package-repos.gpg | gpg --dearmor -o /usr/share/keyrings/openziti.gpg
echo "deb [signed-by=/usr/share/keyrings/openziti.gpg] https://packages.openziti.org/zitipax-openziti-deb-stable jammy main" >/etc/apt/sources.list.d/openziti.list
$STD apt-get update
$STD apt-get install -y ziti-edge-tunnel
sed -i '0,/^ExecStart/ { /^ExecStart/ { n; s|^ExecStart.*|ExecStart=/opt/openziti/bin/ziti-edge-tunnel run-host --verbose=${ZITI_VERBOSE} --identity-dir=${ZITI_IDENTITY_DIR}| } }' /usr/lib/systemd/system/ziti-edge-tunnel.service
systemctl daemon-reload
msg_ok "Installed openziti"

read -r -p "Please paste an identity enrollment token(JTW)" prompt
if [[ ${prompt} ]]; then
    msg_info "Adding identity"
    echo "${prompt}" >/opt/openziti/etc/identities/identity.jwt
    chown ziti:ziti /opt/openziti/etc/identities/identity.jwt
    systemctl enable -q --now ziti-edge-tunnel
    msg_ok "Service Started"
else
    systemctl enable -q ziti-edge-tunnel
    msg_error "No identity provided; please place an identity file in /opt/openziti/etc/identities/ and restart the service"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://prowlarr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y sqlite3
msg_ok "Installed Dependencies"

msg_info "Installing Prowlarr"
temp_file="$(mktemp)"
mkdir -p /var/lib/prowlarr/
chmod 775 /var/lib/prowlarr/
cd /var/lib/prowlarr/
RELEASE=$(curl -fsSL https://api.github.com/repos/Prowlarr/Prowlarr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/Prowlarr/Prowlarr/releases/download/v${RELEASE}/Prowlarr.master.${RELEASE}.linux-core-x64.tar.gz" -o "$temp_file"
$STD tar -xvzf "$temp_file"
mv Prowlarr /opt
chmod 775 /opt/Prowlarr
msg_ok "Installed Prowlarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prowlarr.service
[Unit]
Description=Prowlarr Daemon
After=syslog.target network.target
[Service]
UMask=0002
Type=simple
ExecStart=/opt/Prowlarr/Prowlarr -nobrowser -data=/var/lib/prowlarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now prowlarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

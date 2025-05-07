#!/usr/bin/env bash

#scripts by warren  
# Source: https://jellyfin.org/

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

msg_info "Installing Jellyfin"
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
# If the keyring directory is absent, create it
if [[ ! -d /etc/apt/keyrings ]]; then
  mkdir -p /etc/apt/keyrings
fi
# Download the repository signing key and install it to the keyring directory
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/jellyfin.gpg
curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub | gpg --dearmor --yes --output /usr/share/keyrings/nvidia-drivers.gpg
# Install the Deb822 format jellyfin.sources entry
cat <<EOF >/etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${PCT_OSTYPE}
Suites: ${VERSION}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
cat <<EOF >/etc/apt/sources.list.d/nvidia-drivers.list
deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /
EOF
EOF
cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main non-free non-free-firmware contrib
EOF
# Install Jellyfin and nvidia using the metapackage (which will fetch jellyfin-server, jellyfin-web, and jellyfin-ffmpeg5)
$STD apt-get update
$STD apt-get install -y build-essential gcc dirmngr ca-certificates software-properties-common apt-transport-https dkms curl
$STD apt-get install -y nvidia-driver
$STD apt-get install -y cuda-driver
$STD apt-get install -y cuda
$STD apt-get install -y jellyfin
sed -i 's/"MinimumLevel": "Information"/"MinimumLevel": "Error"/g' /etc/jellyfin/logging.json
chown -R jellyfin:adm /etc/jellyfin
sleep 10
systemctl restart jellyfin
if [[ "$CTTYPE" == "0" ]]; then
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:root,jellyfin/' -e 's/^render:x:108:root,jellyfin$/ssl-cert:x:108:/' /etc/group
else
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:jellyfin/' -e 's/^render:x:108:jellyfin$/ssl-cert:x:108:/' /etc/group
fi
msg_ok "Installed Jellyfin"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

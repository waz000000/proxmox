#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/waz000000/proxmox/refs/heads/main/misc/build.func)
#scripts by warren
# Source: https://jellyfin.org/

APP="Jellyfin"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-12}"
var_ram="${var_ram:-16000}"
var_disk="${var_disk:-40}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /usr/lib/jellyfin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} LXC"
  $STD apt-get update
  $STD apt-get -y upgrade
  $STD apt-get -y --with-new-pkgs upgrade jellyfin jellyfin-server
  msg_ok "Updated ${APP} LXC"
  exit
}

sudo bash -c 'echo "deb http://deb.debian.org/debian bookworm main non-free non-free-firmware contrib" >> /etc/apt/sources.list'
apt install build-essential gcc dirmngr ca-certificates software-properties-common apt-transport-https dkms curl -y
curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub | sudo gpg --dearmor | sudo tee /usr/share/keyrings/nvidia-drivers.gpg >/dev/null 2>&1
echo 'deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /' | sudo tee /etc/apt/sources.list.d/nvidia-drivers.list
apt update
apt install nvidia-driver nvidia-cuda-toolkit -y
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8096${CL}"

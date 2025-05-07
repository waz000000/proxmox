#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://thelounge.chat/

APP="The-Lounge"
var_tags="${var_tags:-irc}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /usr/lib/systemd/system/thelounge.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! dpkg -l build-essential >/dev/null 2>&1; then
    $STD apt-get update
    $STD apt-get install -y build-essential
  fi
  if ! npm list -g node-gyp >/dev/null 2>&1; then
    $STD npm install -g node-gyp
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/thelounge/thelounge-deb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop thelounge
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    $STD apt-get install --only-upgrade nodejs
    cd /opt
    curl -fsSL "https://github.com/thelounge/thelounge-deb/releases/download/v${RELEASE}/thelounge_${RELEASE}_all.deb" -o $(basename "https://github.com/thelounge/thelounge-deb/releases/download/v${RELEASE}/thelounge_${RELEASE}_all.deb")
    dpkg -i ./thelounge_${RELEASE}_all.deb
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start thelounge
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf "/opt/thelounge_${RELEASE}_all.deb"
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required.  ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"

#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/aceberg/WatchYourLAN

APP="WatchYourLAN"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
    if [[ ! -f /lib/systemd/system/watchyourlan.service ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating $APP"
    systemctl stop watchyourlan.service
    cp -R /data/config.yaml config.yaml
    RELEASE=$(curl -fsSL https://api.github.com/repos/aceberg/WatchYourLAN/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4)
    curl -fsSL "https://github.com/aceberg/WatchYourLAN/releases/download/$RELEASE/watchyourlan_${RELEASE}_linux_amd64.deb" -o $(basename "https://github.com/aceberg/WatchYourLAN/releases/download/$RELEASE/watchyourlan_${RELEASE}_linux_amd64.deb")
    dpkg -i watchyourlan_${RELEASE}_linux_amd64.deb
    cp -R config.yaml /data/config.yaml
    sed -i 's|/etc/watchyourlan/config.yaml|/data/config.yaml|' /lib/systemd/system/watchyourlan.service
    rm watchyourlan_${RELEASE}_linux_amd64.deb config.yaml
    systemctl enable -q --now watchyourlan
    msg_ok "Updated $APP"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8840${CL}"

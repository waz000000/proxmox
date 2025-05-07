#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/waz000000/proxmox/refs/heads/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT |
# Source: https://github.com/navidrome/navidrome

APP="Navidrome"
var_tags="${var_tags:-music}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
    if [[ ! -d /var/lib/navidrome ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -fsSL https://api.github.com/repos/navidrome/navidrome/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
    if [[ ! -f /opt/${APP}_version.txt ]]; then touch /opt/${APP}_version.txt; fi
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping Services"
        systemctl stop navidrome
        msg_ok "Services Stopped"

        msg_info "Updating ${APP} to ${RELEASE}"
        TMP_DEB=$(mktemp --suffix=.deb)
        curl -fsSL -o "${TMP_DEB}" "https://github.com/navidrome/navidrome/releases/download/${RELEASE}/navidrome_${RELEASE#v}_linux_amd64.deb"
        $STD apt-get install -y "${TMP_DEB}"
        echo "${RELEASE}" >/opt/"${APP}_version.txt"
        msg_ok "Updated Navidrome"

        msg_info "Starting Services"
        systemctl start navidrome
        msg_ok "Started Services"

        msg_info "Cleaning Up"
        rm -f "${TMP_DEB}"
        msg_ok "Cleaned"
        msg_ok "Updated Successfully"
    else
        msg_ok "No update required. ${APP} is already at ${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4533${CL}"

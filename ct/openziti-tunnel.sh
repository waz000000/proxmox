#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: emoscardini
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openziti/ziti

APP="openziti-tunnel"
var_tags="${var_tags:-network;openziti-tunnel}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
   header_info
   check_container_storage
   check_container_resources
   if [[ ! -d /opt/openziti ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
   fi
   msg_info "Updating $APP LXC"
   $STD apt-get update
   $STD apt-get -y upgrade
   msg_ok "Updated $APP LXC"
   exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Application was assigned the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Address: ${IP}${CL}"
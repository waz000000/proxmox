#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/StarFleetCPTN/GoMFT

APP="GoMFT"
var_tags="${var_tags:-backup}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -d "/opt/gomft" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! dpkg -l | grep -q "^ii.*build-essential"; then
    $STD apt-get install -y build-essential
  fi
  if [[ ! -f "/usr/bin/node" ]]; then
    mkdir -p /etc/apt/keyrings
    curl -fsSL "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
    $STD apt-get update
    $STD apt-get install -y nodejs
  fi
  RELEASE=$(curl -fsSL "https://api.github.com/repos/StarFleetCPTN/GoMFT/releases/latest" | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping $APP"
    systemctl stop gomft
    msg_ok "Stopped $APP"

    msg_info "Updating $APP to ${RELEASE}"
    rm -f /opt/gomft/gomft
    temp_file=$(mktemp)
    curl -fsSL "https://github.com/StarFleetCPTN/GoMFT/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
    tar -xzf "$temp_file"
    cp -rf "GoMFT-${RELEASE}"/* /opt/gomft/
    cd /opt/gomft
    $STD npm install
    $STD npm run build
    $STD "$HOME"/go/bin/templ generate
    export CGO_ENABLED=1
    export GOOS=linux
    $STD go build -o gomft
    chmod +x /opt/gomft/gomft
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to ${RELEASE}"

    msg_info "Cleaning Up"
    rm -f "$temp_file"
    rm -rf "$HOME/GoMFT-v.${RELEASE}/"
    msg_ok "Cleanup Complete"

    msg_info "Starting $APP"
    systemctl start gomft
    msg_ok "Started $APP"

    msg_ok "Update Successful"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"

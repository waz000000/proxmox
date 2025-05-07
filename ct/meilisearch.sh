#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.meilisearch.com/

APP="Meilisearch"
var_tags="${var_tags:-full-text-search}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-7}"
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

  if [[ ! -f /opt/Meilisearch_version.txt ]]; then
    msg_error "No Meilisearch Installation Found!"
    exit
  fi
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Meilisearch Update" --radiolist --cancel-button Exit-Script "Spacebar = Select" 10 58 2 \
    "1" "Update Meilisearch" ON \
    "2" "Update Meilisearch-UI" OFF \
    3>&1 1>&2 2>&3)

  if [ "$UPD" == "1" ]; then
    msg_info "Stopping Meilisearch"
    systemctl stop meilisearch
    msg_ok "Stopped Meilisearch"

    msg_info "Updating Meilisearch"
    tmp_file=$(mktemp)
    RELEASE=$(curl -s https://api.github.com/repos/meilisearch/meilisearch/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    curl -fsSL https://github.com/meilisearch/meilisearch/releases/latest/download/meilisearch.deb -o $tmp_file
    $STD dpkg -i $tmp_file
    echo "$RELEASE" >/opt/meilisearch_version.txt
    msg_ok "Updated Meilisearch"

    msg_info "Starting Meilisearch"
    systemctl start meilisearch
    msg_ok "Started Meilisearch"
    exit
  fi

  if [ "$UPD" == "2" ]; then
    if [[ ! -f /opt/Meilisearch-ui_version.txt ]]; then
      msg_error "No Meilisearch-UI Installation Found!"
      exit
    fi
    msg_info "Stopping Meilisearch-UI"
    systemctl stop meilisearch-ui
    msg_ok "Stopped Meilisearch-UI"

    msg_info "Updating Meilisearch-UI"
    tmp_file=$(mktemp)
    tmp_dir=$(mktemp -d)
    RELEASE_UI=$(curl -s https://api.github.com/repos/riccox/meilisearch-ui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    cp /opt/meilisearch-ui/.env.local /tmp/.env.local.bak
    rm -rf /opt/meilisearch-ui
    mkdir -p /opt/meilisearch-ui
    curl -fsSL "https://github.com/riccox/meilisearch-ui/archive/refs/tags/${RELEASE_UI}.zip" -o $tmp_file
    unzip -q "$tmp_file" -d "$tmp_dir"
    mv "$tmp_dir"/*/* /opt/meilisearch-ui/
    cd /opt/meilisearch-ui
    sed -i 's|const hash = execSync("git rev-parse HEAD").toString().trim();|const hash = "unknown";|' /opt/meilisearch-ui/vite.config.ts
    mv /tmp/.env.local.bak /opt/meilisearch-ui/.env.local
    $STD pnpm install
    echo "$RELEASE_UI" >/opt/meilisearch-ui_version.txt
    msg_ok "Updated Meilisearch-UI"

    msg_info "Starting Meilisearch-UI"
    systemctl start meilisearch-ui
    msg_ok "Started Meilisearch-UI"
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}meilisearch: http://${IP}:7700$ | meilisearch-ui: http://${IP}:24900${CL}"

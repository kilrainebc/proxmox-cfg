#!/bin/bash
#
#   Author:  kilrainebc
#   Version: 1.0
#   Description: Function library for OTHER tasks during Proxmox Setup

# shellcheck disable=SC2120

#######################################
# Description:
#   Removes Proxmox subscription reminder, and creates incron rule for application on every update.
#######################################
function setup_pmx_noreminder () {
  printf "root" >> /etc/incron.allow
  local file
  file="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
  cp "$file" "$file.bkp"
  sed -i "s/.data.status.toLowerCase() !== 'active'/.data.status.toLowerCase() == 'active'/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
  systemctl restart pveproxy.service
  diff "$file" "$file.bkp"

  file="proxmox_noreminder"
  cp "./scripts/$file" "/usr/local/bin/$file"
  chmod +x "/usr/local/bin/$file"
  echo "$file"
  printf "/usr/share/javascript/proxmox-widget-toolkit/ IN_CREATE /usr/local/bin/%s \$#\n" "$file" >> /tmp/incron.table-temp
  incrontab -u root /tmp/incron.table-temp

  tail /var/log/syslog | grep incrond
  tail -n 30 /var/log/incron.log
  apt-get install --reinstall proxmox-widget-toolkit
}

#######################################
# Description:
#   Applies dark theme for Proxmox webGUI.
#######################################
function setup_pmx_darkmode () {
  wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh
  bash PVEDiscordDark.sh install
}

#######################################
# Description:
#   Main other function.
#######################################
function other_config () {
  setup_pmx_darkmode
  setup_pmx_noreminder
}

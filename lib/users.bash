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
  rm -f /tmp/incron.table-temp

  tail /var/log/syslog | grep incrond
  tail -n 30 /var/log/incron.log
  apt-get install --reinstall proxmox-widget-toolkit
}

#######################################
# Description:
#   Applies the standard no-reminder warning.
#######################################
function remove_pmx_noreminder () {
  printf "root" >> /etc/incron.allow
  local file
  file="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
  cp "$file.bkp" "$file" 
  systemctl restart pveproxy.service

  incrontab -r
  apt-get install --reinstall proxmox-widget-toolkit  
}

#######################################
# Description:
#   Applies dark theme for Proxmox webGUI.
#######################################
function setup_pmx_darkmode () {
  local file
  file="PVEDiscordDark.sh"
  if [[ ! -f $file ]]; then
    wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh
  fi
  bash $file install
}

#######################################
# Description:
#   Removes dark theme for Proxmox webGUI.
#######################################
function remove_pmx_darkmode () {
  local file
  file="PVEDiscordDark.sh"
  if [[ -f $file ]]; then
    bash $file uninstall
  fi
}

#######################################
# Description:
#   Reverses changes made by other_config function
#######################################
function remove_other_config () {
  remove_pmx_darkmode
  remove_pmx_noreminder
}

#######################################
# Description:
#   Main other function.
#######################################
function config_other () {
  setup_pmx_darkmode
  setup_pmx_noreminder
}


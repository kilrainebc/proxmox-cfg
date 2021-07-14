#!/bin/bash
#
#   Author:  kilrainebc
#   Version: 1.0
#   Description: Function library for user creation tasks during Proxmox Setup

# shellcheck disable=SC2120

function config_users () {
  local users
  local user
  local admin

  read -p "pvecfg: Please supply a name for a non-root administrator account: " admin  

  users=''
  users+=" $admin"
  users+=' packer terraform ansible'

  for user in $users; do
    password=''
    printf "pvecfg: Creating user: %s \n" $user
    pveum user add "$user"@pam 
    pveum passwd "$user"@pam
    pveum acl modify / --user "$user"@pam --roles Administrator
  done
}



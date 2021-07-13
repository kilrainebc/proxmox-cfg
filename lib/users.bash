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
  local password

  read -p "pvecfg: Please supply a name for a non-root administrator account: " admin  

  users=''
  users+=" $admin"
  users+=' packer terraform ansible'

  for user in $users; do
    password=''
    printf "pvecfg: Creating user: %s \n" $user
    read -p "pvecfg: Please supply a password: " $password
    pveum user add $username --password $password
    pveum acl modify / --user $username --roles Administrator
  done
}



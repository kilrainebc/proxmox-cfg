#!/bin/bash
#
#   Author:  kilrainebc
#   Version: 1.0
#   Description: Function library for 

#######################################
# Description:
#     Undos sources configuration
#######################################
function sources_undo () {
  cp /etc/apt/sources.list.bkp /etc/apt/sources.list
  cp /etc/apt/sources.list.d/pve-enterprise.list.bkp /etc/apt/sources.list.d/pve-enterprise.list 
}

#######################################
# Description:
#     Main sources configuration function
#######################################
function sources_config () {
  cp /etc/apt/sources.list /etc/sources.list.bkp
  cp ../etc/apt/sources.list /etc/apt/sources.list
  cp /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bkp
  sed -i 's/deb/#deb/g' /etc/apt/sources.list.d/pve-enterprise.list
  apt update && apt upgrade -y && apt dist-upgrade
}
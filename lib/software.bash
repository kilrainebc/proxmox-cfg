#!/bin/bash
#
#   Author:  kilrainebc
#   Version: 1.0
#   Description: Description: Function library for software tasks during Proxmox Setup

# shellcheck disable=SC1091

#######################################
# Description:
#   Uninstalls shellcheck util   
#######################################
function uninstall_shellcheck () {
  rm -rf /usr/bin/shellcheck
}

#######################################
# Description:
#     Installs shellcheck util.
#######################################
function install_shellcheck () {
  if [[ ! $(shellcheck --version) ]]; then
    local scversion
    scversion="latest" # or "v0.4.7", or "stable", or "latest"
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.x86_64.tar.xz" | tar -xJv
    cp "shellcheck-${scversion}/shellcheck" /usr/bin/
    rm -rf "shellcheck-${scversion}"    
  fi
}

#######################################
# Description:
#   Uninstalls shfmt util   
#######################################
function uninstall_shfmt ()  {
  rm -rf /usr/local/go/bin/shfmt
}

#######################################
# Description:
#   Installs shfmt util, and go.   
# Globals:
#   $PATH
#######################################
function install_shfmt () {
  if [[ ! $(shfmt --version) ]]; then
    while [[ ! $(go version) ]]; do
      wget https://golang.org/dl/go1.16.5.linux-amd64.tar.gz
      tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz
      {
        printf "export PATH=%s:/usr/local/go/bin" "$PATH"
        printf "export GOPATH=/usr/local/go"
      } >> /etc/profile
      source /etc/profile
    done
    go get mvdan.cc/sh/v3/cmd/shfmt  
  fi
}

#######################################
# Description:
#     installs packages through apt
#######################################
function uninstall_apt_pkgs () {
  local pkgs
  pkgs+=' vim python python-pip'
  pkgs+=' zsh'
  pkgs+=' neofetch'
  pkgs+=' incron'
  apt-get -y --purge remove "$pkgs" 
}

#######################################
# Description:
#     installs packages through apt
#######################################
function install_apt_pkgs () {
  local pkgs
  pkgs+=' vim python python-pip'
  pkgs+=' zsh'
  pkgs+=' neofetch'
  pkgs+=' incron'
  apt-get -y install "$pkgs" 
}

#######################################
# Description:
#     removes installations made under software_config function
#######################################
function uninstall_software_config () {
  uninstall_shellcheck
  uninstall_shfmt
  uninstall_apt_pkgs
}

#######################################
# Description:
#     main install function
#######################################
function software_config () {
  install_shellcheck
  install_shfmt
  install_apt_pkgs
  # create function for dotfiles
}

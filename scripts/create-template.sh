#!/bin/bash
# 
# Author: kilrainebc
# Description: Create cloud template image

#   interactive     ./script 
#   non-interactive ./script /path/to/file
# $1 os_id (1 || 2 || 3) 
# $2 name 
# $3 vmid 
# $4 

# shellcheck disable=SC2089,SC1090
function set_defaults () {

  # Template OS
  if [[ -z $os_id ]]; then
    printf "
    * Available templates to generate: \n
    centos
    debian 
    arch
    \n"
    read -rp "* Enter the number that corresponds to the distro you would like to use: " os_id   
  fi

  # Template ID
  if [[ -z $vmid ]]; then
    local vmid_default
    vmid_default=$(qm list | tail -1 | awk '{print $1}')
    if [[ -z $vmid_default ]]; then
      vmid_default=100
    fi
    read -rp "Enter a VM ID [default: $vmid_default]: " vmid
    vmid=${vmid:-$vmid_default}
  fi

  # Memory
  if [[ -z $memory ]]; then
    local memory_default
    memory_default=1024
    read -rp "Enter memory (in MBs) [default: $memory_default]: " memory
    memory=${memory:-$memory_default}
  fi

  # Bridge
  if [[ -z $bridge ]]; then
    local bridge_default
    bridge_default=$(brctl show | head -2 | tail -1 | awk '{print $1}' )
    read -rp "Enter bridge [default: $bridge_default]: " bridge
    bridge=${bridge:-$bridge_default}
  fi 

  # VM Image
  if [[ -z $vm_image ]]; then
      get_cloud_image
  else
    if [[ ! -f $vm_image ]]; then
      get_cloud_image
    fi
  fi

  # Template Name
  if [[ -z $name ]]; then
    name=$os_name-template
  fi

  # Storage Volume
  if [[ -z $storage_volume ]]; then
    local storage_volume_default
    storage_volume_default=$(pvesm status | grep lvmthin | tail -1 | awk '{print $1}' )
    read -rp "Enter storage volume [default: $storage_volume_default]: " storage_volume
    storage_volume=${storage_volume:-$storage_volume_default}
  fi

  # IP
  if [[ -z $ip ]]; then
    local ip_default
    ip_default=dhcp
    read -rp "Enter IP [default: $ip_default]: " ip
    ip=${ip:-$ip_default}
  fi

  # Gateway
  if [[ -z $gw ]]; then
    if [[ $ip != "dhcp" ]]; then
        gw=$(awk -F"." '{print $1"."$2"."$3".1"}'<<<"$ip")
    fi
  fi

  # citype
  if [[ -z $citype ]]; then
    local citype_default
    citype_default=none
    read -rp "Enter citype [default: $citype_default]: " citype
    citype=${citype:-$citype_default}
  fi

  # resize
  if [[ -z $resize ]]; then
    local resize_default
    resize_default="+8G"
    read -rp "Enter size of resize [default: $resize_default]: " resize
    resize=${resize:-$resize_default}
  fi

  # user config
  if [[ -z $userconfig ]]; then
    local userconfig_default
    userconfig_default="/path/to/sample-cloud-init-config.yml"
    read -rp "Enter the name of the cloud-init-config.yml (skipped if file not found) [default: $userconfig_default]: " userconfig
    userconfig=${userconfig:-$userconfig_default}
  fi  

  # snippets
  if [[ -z $snippets_path ]]; then
    local snippets_path_default
    snippets_path_default="/var/lib/vz/snippets"
    read -rp "Enter path to snippets [default: $snippets_path_default]: " snippets_path
    snippets_path=${snippets_path:-$snippets_path_default}
    if [[ ! -d $snippets_path ]]; then
      printf "Path supplied is not valid directory %s\n" $snippets_path
      printf "snippets path is $snippets_path\n"
      #exit 64
    fi
  fi    

  # snippets volume
  if [[ -z $snippets_volume ]]; then
      if [[ $snippets != "/var/lib/vz/snippets" ]]; then
      local snippets_volume_default
      snippets_volume_default="assets"
      read -rp "Enter storage volum that contains $snippets [default: $snippets_volume_default]: " snippets_volume
      snippets_volume=${snippets_volume:-$snippets_volume_default}
    fi 
  fi
  # sshkey
  if [[ -z $sshkey ]]; then
    local sshkey_default
    sshkey_default="$HOME/.ssh/id_rsa.pub"
    read -rp "Enter path to SSH key you'd like to use for default user [default: $sshkey_default]: " sshkey
    sshkey=${sshkey:-$sshkey_default} 
    if [[ ! -f $sshkey ]]; then
      printf "sshkey supplied is not valid"
      exit 64
    fi
  fi

}

function get_cloud_image () {
  
  case $os_id in
    centos)
      os_name=centos8
      vm_image=CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2
      wget -P /tmp -N https://cloud.centos.org/centos/8/x86_64/images/$vm_image
      note="\n ## Default user is 'centos' ## \n
      ## use 'hostnamectl set-hostname' inside vm ## \n"
      printf "%s\n" "$note"
      ;;

    debian)
      os_name=debian10
      vm_image=debian-10-openstack-amd64.qcow2
      wget -P /tmp -N https://cdimage.debian.org/cdimage/openstack/current-10/$vm_image
      note="\n## Default user is 'debian'\n"
      printf "%s\n" "$note"
      ;;

    arch)
      os_name=arch
      vm_image=arch-openstack-LATEST-image-bootstrap.qcow2
      wget -P /tmp -N https://linuximages.de/openstack/arch/$vm_image
      note="\n## Default user is 'arch'\n## NOTE: Setting a password via cloud-config does not work.\n#  Resizing does not happen automatically inside the VM\n"
      printf "%s\n" "$note"
      ;;

    *)
      printf "\n** Unknown OS number. Please use one of the above!\n"
      exit 64
      ;;
  esac

  vm_image="/tmp/$vm_image"
  echo $os_name
}

function create_vm_from_image () {
    echo "os_id: $os_id"
    echo "name: $name"
    echo "vmid: $vmid"
    echo "memory: $memory"
    echo "bridge: $bridge"
    echo "storage: $storage_volume" 
    echo "snippets path: $snippets_path"

########

  printf "\n ** Creating VM with %s MB using network bridge %s \n" "$memory" "$bridge"
  qm create "$vmid" --name "$name" --memory "$memory" --net0 virtio,bridge="$bridge"

  printf "\n ** Importing the disk in qcow2 format (as 'Unused Disk 0') \n"
  qm importdisk "$vmid" $vm_image "$storage_volume" -format qcow2
  sleep 15

  printf "\n ** Attaching the disk to the vm using VirtIO SCSI \n"
  qm set "$vmid" --scsihw virtio-scsi-pci --scsi0 "$storage_volume":vm-"$vmid"-disk-0
  sleep 15

  printf "\n ** Setting boot and display settings with serial console \n"
  qm set "$vmid" --boot c --bootdisk scsi0 --serial0 socket --vga serial0

  printf "\n ** Using a dhcp server on %s (or change to static IP) \n" "$bridge"
  if [[ $ip != "dhcp" ]]; then
    qm set "$vmid" --ipconfig0 ip="$ip"/24,gw="$gw"
  else
    qm set "$vmid" --ipconfig0 ip="$ip"
  fi
  
  printf "\n ** Creating a cloudinit drive managed by Proxmox \n"
  qm set "$vmid" --ide2 "$storage_volume":cloudinit

  printf "\n ** Specifying the cloud-init configuration format\n"
  qm set "$vmid" --citype "$citype"

  printf "\n** Increasing the disk size\n"
  qm resize "$vmid" scsi0 "$resize"

  printf "#** Made with create-cloud-template.sh - https://gist.github.com/chriswayg/43fbea910e024cbe608d7dcb12cb8466\n" >> /etc/pve/nodes/"$HOSTNAME"/qemu-server/"$vmid".conf
}

function config_cloudinit () {
  printf "\n ** The script can add a cloud-init configuration with users and SSH keys from a file in the current directory. \n"
  if [[ -f $userconfig ]]; then
    printf "\n ** Added user configuration \n"
    cp -v "$userconfig" "$snippets_path"/"$vmid"-os_name-"$userconfig"
    qm set "$vmid" --cicustom "$snippets_volume:snippets/$vmid-os_name-userconfig"
  else
    printf "\n ** Skipping config file, as none was found \n\n ** Adding SSH key \n"
    qm set "$vmid" --sshkey "$sshkey"
    printf "\n"
    read -rp "Supply an optional password for the default user (press Enter for none): " password
    if [[ -n "$password" ]]; then
      printf "\n ** Adding the password to the config \n"
      qm set "$vmid" --cipassword "$password"
      printf "#* a password has been set for the default user \n" >> /etc/pve/nodes/"$HOSTNAME"/qemu-server/"$vmid".conf
    fi
    printf "#- cloud-config used: via Proxmox \n" >> /etc/pve/nodes/"$HOSTNAME"/qemu-server/"$vmid".conf
  fi
}

function create_template_from_vm () {
  printf "\n ** Creating template from VM ** \n"
  printf "\n *** The following cloud-init configuration will be used ***\n"
  printf "\n-------------  User ------------------\n"
  qm cloudinit dump "$vmid" user
  printf "\n-------------  Network ---------------\n"
  qm cloudinit dump "$vmid" network

  qm template "$vmid"

  #printf "\n** Removing previously downloaded image file\n\n"
  #rm -v /tmp/$vm_image
  printf "%s\n\n" "$note"
}

function main () {
  if [[ -n $1 ]]; then
    if [[ -f $1 ]]; then
      source "$1"
    fi
  else
    printf "No parameter passed for variables file!"
  fi

  set_defaults  
  create_vm_from_image
  config_cloudinit
  create_template_from_vm
}

main "$@"

#!/bin/bash
#
#   Author:  kilrainebc
#   Version: 1.0
#   Description: Function library for storage tasks during Proxmox Setup 

#######################################
# Description:
#   Restores Proxmox storage configuration to default state.
#######################################
function clean_storage_config () {
  local dev
  local file

  # remove logical volumnes
  echo "y" | lvremove nvme/data
  echo "y" | lvremove hdd/data

  # remove logical volumes
  echo "y" | vgremove nvme
  echo "y" | vgremove hdd

  # remove physical volumes
  echo "y" | pvremove /dev/nvme0n1
  echo "y" | pvremove /dev/sdb3

  # remove partition table on /dev/sdb
  dev="/dev/sdb"
  sgdisk -Z $dev
  kpartx -u $dev 
  clear_devmapper $dev

  # Unmount mountpoints
  if grep -qs '/mnt/backup' /proc/mounts; then
    umount /mnt/backup
  fi

  if grep -qs '/mnt/assets' /proc/mounts; then
    umount /mnt/assets
  fi

  # If backups exist and are older than configs, restore them.  If backups don't exist, create them.
  file="/etc/fstab"
  if [[ -f "$file.bkp" ]]; then
    if [[ $file -nt "${file}.bkp" ]]; then
      mv "$file.bkp" $file
    fi
  else
    cp $file "$file.bkp"
  fi
 
  file="/etc/pve/storage.cfg"
  if [[ -f "$file.bkp" ]]; then
    if [[ $file -nt "${file}.bkp" ]]; then
      mv "$file.bkp" $file
    fi
  else
    cp $file "$file.bkp"
  fi
}

#######################################
# Description:
#   Creates partition with EXT4 filesystem.
# Globals:
#   None.
# Arguments:
#   Device File (e.g. /dev/sdx)
#   Size in GBs (e.g. '30')
#######################################
function create_partition() {
  local free
  local partition

  if [[ -z $1 ]]; then
    printf "[error] - %s - please specify a parameter for drive\n" "${FUNCNAME[0]}" >&2
    exit 64
  fi

  if [[ ! -b $1 ]]; then
    printf "[error] - %s - $1 is not a block device\n" "${FUNCNAME[0]}" >&2
    exit 64
  fi

  free=$(parted "$1" unit GiB print free | grep "Free" | awk '{print $3}' | tail -1 | sed 's/GiB//g')

  if [[ -z $free ]]; then
    free=$(sfdisk --list "$1" | head -1 | awk '{print $3}')
    free=${free%.*}
  fi

  if [[ -n $2 ]]; then
    if (( $(echo "$size < $free" | bc -l) )); then 
      echo "$2 is smaller than free space $free"
      echo "sgdisk $1 -n 0::${2}G"
      sgdisk "$1" -n 0::"${2}"G
    fi
  else
    echo "\$2 does not exist: $2"
    echo "sgdisk $1 -n 0"
    sgdisk "$1" -n 0
  fi

  partition=$(sfdisk --list "$1" | tail -1 | awk '{print $1}')
  echo "mkfs.ext4 $partition -F"
  printf "y\n" | mkfs.ext4 "$partition" -F
  if [[ ! $(printf "y\n" | mkfs.ext4 "$partition" -F) ]]; then
    clear_devmapper "$1"
    printf "y\n" | mkfs.ext4 "$partition" -F
    kpartx -u "$1"
  fi
}

#######################################
# Description:
#   Gets size of logical volumes.  
# Arguments:
#   LV Name Filter (e.g. "data" or "root")
# Outputs:
#   Writes total size of logical volumes
#######################################
function get_lv_size() {
  lvs | grep "$1" | sed 's/<//g; s/g//g' | awk '{ total += $4}; END { print total }'
}

#######################################
# Description:
#   Creates LVM configuration on a block device.
# Arguments:
#   Device File (e.g. /dev/sdx)
#   Volume Group Name
#   Logical Volume Name
#######################################
function create_lvm() {

  if [[ $# -lt 3 ]]; then
    printf "[error] - %s - Requires /path/to/device, VG Name, LV Name\n" "${FUNCNAME[0]}" >&2
    exit 64     
  fi

  if [[ ! -b $1 ]]; then
    printf "[error] - %s - $1 is not a block device\n" "${FUNCNAME[0]}" >&2
    exit 64
  fi

  printf "y\n" | pvcreate "$1"
  printf "y\n" | vgcreate "$2" "$1"
  printf "y\n" | lvcreate --type thin-pool --name "$3" -l 100%FREE "$2"
}

#######################################
# Description:
#     Mounts partition and adds to fstab
# Arguments:
#   Mount Point (e.g. /path/to/mountpoint)
#   Device File (e.g. /dev/sdx)
#######################################
function mount_partition() {

  if [[ $# -lt 2 ]]; then
    printf "[error] - %s - requires /path/to/mountpoint and /path/to/device \n" "${FUNCNAME[0]}" >&2
    exit 64
  fi

  if [[ ! -b $2 ]]; then 
    printf "[error] - %s - $1 is not a block device\n" "${FUNCNAME[0]}" >&2
    exit 64
  fi

  if [[ ! -d $1 ]]; then
    mkdir "$1"
  fi

  echo "mount $2 $1"
  mount "$2" "$1"
  printf "\n%s ext4 nofail 0 0\n" "$1" >> /etc/fstab
}

#######################################
# Description:
#     Update /etc/pve/storage.cfg stanzas
# TODO: Dynamically create stanzas.  Currently updates with hard-coded printf statements.0
#######################################
function update_storage_stanzas() {
  local file
  
  file="/etc/pve/storage.cfg"
  sed -i 's/local-lvm/ssd/g' "$file"
  sed -i 's/backup,vztmpl,iso/vztmpl,iso,snippets/g' "$file"

  cp ./etc/pve/storage.cfg "$file"
}

#######################################
# Description:
#   Clears stale devmapper records.  
# Globals:
#   Device File (e.g. /dev/sdx)
#######################################
function clear_devmapper() {  
  local scsi_id
  local dm_ids

  scsi_id=$(basename "$1")
  dm_ids=$(dmsetup info -c | grep "${scsi_id}" | awk '{print $1}')
    
  for dm_id in $dm_ids; do
    echo "dm_id: ${dm_id}"
    dmsetup remove "${dm_id}" 
  done
}

#######################################
# Description:
#   Main storage function.  
#######################################
function storage_config() {
  local dev
  local size
  local old_size

  clean_storage_config

  # make a function ?
  local sda3_free
  sda3_free=$(pvs | grep sda3 | awk '{print $6}')
    if [[ $sda3_free -ne "0" ]]; then
      lvextend pve/data /dev/sda3
    fi

  dev="/dev/nvme0n1"
  create_lvm $dev nvme data 

  dev="/dev/sdb"

  size=$(get_lv_size data)
  size=${size%.*}
  create_partition "$dev" "$size" 

  old_size=$size
  size=$(get_lv_size root)
  size=${size%.*}

  size=$(echo "$size + $old_size" | bc -l) 
  create_partition "$dev" "$size"

  create_partition "$dev"
  create_lvm "${dev}3" hdd data #VG_name #LV_name

  mount_partition /mnt/backup /dev/sdb1
  mount_partition /mnt/assets /dev/sdb2 

  update_storage_stanzas # run once at end
}

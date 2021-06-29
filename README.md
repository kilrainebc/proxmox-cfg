# pvecfg

Utility for customizing Proxmox VE nodes.  

## Description

This project is for customizing and configuring Proxmox VE nodes.  Running this utility will apply changes to package sources, installed software, storage, and more.  In the future, this project will also cover networking, users (such as svc accounts for terraform/ansible), and more.  

### Directory Structure:
```
./
  `--/etc/                      directory for etc configuration files
    `--/pve/
      `--storage.cfg
    `--/apt/
      `--sources.list
  `--/lib/                      directory for function libraries
    `--sources.bash
    `--storage.bash
    `--storage.bash
    `--other.bash
  `--/scripts/                  directory for scripts       
    `--proxmox_noreminder
  `--pvecfg
```

## Getting Started

### Dependencies

* Proxmox VE 6

### Installing

#### Download 
* ##### git
```
git clone https://github.com/kilrainebc/proxmox-cfg.git
cd pvecfg
```
* ##### wget
```
wget -qO- https://github.com/kilrainebc/proxmox-cfg/archive/main.tar.gz | tar -xvz
cd pvecfg-main
```
* ##### cURL
```
curl -LJOs https://github.com/kilrainebc/proxmox-cfg/archive/main.tar.gz
tar xvzf proxmox-cfg-main.tar.gz
cd pvecfg-main
```

#### Necessary modifications needed to be made to files/folders

Special attention should be made to the *\*.bash* library files in the lib dir, as well as the configuration files in the *./etc* directory and subdirectory.

##### Libaries & their functions 

Each library defines specific functions for a subset of tasks.  There are two types of functions - main and auxiliary.  

An "auxiliary" function performs a sole task.  Examples of these types would be the *install_apt_pkgs* or *setup_pmx_noreminder* functions.  You can identify them because they begin with a verb, like "install", "clear", "get", etc.

A "main" function is one that begins with the name of the library (e.g. *storage_config* within *storage.bash*).  These functions chain together auxiliary functions of the libary, and any other necessary logic, so that the desired configuration can take place.

Below is a short breakdown about each library - while this is hopefully useful, you will still need to read the source code and make the appropriate edits - particularly to ***storage.bash*** as the main function of that library is geared towards a specific hardware setup and desired end state.  

* ``` sources.bash ``` -- updates the sources for apt - this may get merged with *software.bash*, but for now it is separate.
* ``` software.bash ``` -- installation of software and packages.  Packages can easily be edited within the *install_apt_pkgs* function - see the sourcecode for examples.
* ``` storage.bash ``` -- storage configurations - such as creating partitions, setting up LVM on additional drives, creating and mounting filesystems, etc.  Definitely edit this one.
* ``` other.bash ``` -- other configurations - like applying the dark theme, or ensuring the "No Valid Subscription" message are removed.  

##### ./etc/ configuration files

Just like you will want to take a look at and edit the libraries - you will also want to look at editing the conf files within the *./etc/* directory.  

Also, just like the libaries, you will want to look at the storage configuration in particular (*./etc/pve/storage.cfg*) -- this is highly tuned - without the same physical hardware, LVM setup, and *storage_config* function - this file will be useless to you (outside of providing an example of how to craft your own).  

Below is short breakdown of each conf file - again, look at the source code and make appropriate edits.

* ```./pve/storage.cfg ``` -- storage configuration -- see (proxmox storage docs)[https://pve.proxmox.com/wiki/Storage] for more info.
* ```./apt/sources.list ``` -- APT sources configuration -- contains some (Debian)[https://debian.org] repos as well as the pve-no-subscription repo from (Proxmox)[https://proxmox.com].

#### Executing program

```
./pvecfg apply
```

#### Uninstalling program

```
./pvecfg uninstall
```


## Help

### Storage issues

Occassionally, problems arise during storage configuration.  In testing, it appears to occur when the system has stale records in devmapper.
This error can be identified by the below errors:

* ```<partition device file> is apparently in use by the system; will not make a filesystem here!``` (mkfs)
* ```mount: /mnt/backup: <partition device file> already mounted or mount point busy.  ``` (mount)
* ```Can't open <partition device file> exclusively.  Mounted filesystem? ``` (pvcreate)

The *storage.bash* libary contains a function *clear_devmapper* to help with this.  Simply source the file manually, call the function (with the disk device file of the disk passed as the argument -e.g. if it complains about /dev/sdX1, pass /dev/sdX! ), and re-run the install (see below).

```
source ./lib/storage.bash
clear_devmapper <disk device file>
./pvecfg apply
```

The *create_partition* function currently has some error handling to catch this, and it is always run within the *clear_storage_config* as well, but a more robust solution is required. 

## Authors

[Blake Kilraine](https://linkedin.com/in/blake-kilraine)  

## Version History

* 1.0
    * Initial Release

## License

TBD - This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.

* [PVEDiscordDark](https://github.com/Weilbyte/PVEDiscordDark)
* [xshok-proxmox](https://github.com/extremeshok/xshok-proxmox)
* [proxmox-server-scripts](https://github.com/chriswayg/proxmox-server-scripts)

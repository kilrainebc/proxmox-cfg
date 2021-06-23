# Proxmox-Cfg

Utility for customizing Proxmox VE nodes.  

## Description

An in-depth paragraph about your project and overview of use.

This project is for customizing and configuring Proxmox VE nodes.  Running this utility will apply changes to package sources, installed software, storage (LVM, partitions, and Proxmox's storage.cfg stanzas).  In the future, this project will also cover networking - mostly linux bridges other than vmbr0 - and users (such as terraform/ansible svc users, and a non-root admin).

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
  `--install
```

## Getting Started

### Dependencies

* Proxmox VE 6

### Installing

#### Download 
* ##### git
```
git clone https://github.com/kilrainebc/proxmox-cfg.git
cd proxmox-cfg
```
* ##### wget
```
wget -qO- https://github.com/kilrainebc/proxmox-cfg/archive/main.tar.gz | tar -xvz
cd proxmox-cfg-main
```
* ##### cURL
```
curl -LJOs https://github.com/kilrainebc/proxmox-cfg/archive/main.tar.gz
tar xvzf proxmox-cfg-main.tar.gz
cd proxmox-cfg-main
```

### Necessary modifications needed to be made to files/folders

Special attention should be made to the *\*.bash* files in the lib dir.  Especially the following: ***storage.bash and software.bash***

### Executing program

```
./install
```

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

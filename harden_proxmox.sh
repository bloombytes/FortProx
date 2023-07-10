#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "\u11118 checking if proxmox server is up-to-date..."
apt-get update > /dev/null
UPDATES=$(apt-get -s upgrade | grep -i "upgraded," | cut -d' ' -f1)
if [[ $UPDATES -eq 0 ]]; then
    echo "\u10003 proxmox server is up-to-date"
else
    echo "\u26A0 proxmox server has $UPDATES updates available"
fi

echo "\u11118 checking if proxmox server has non-default root password..."
ROOT_PW=$(grep -c 'root:$6$' /etc/shadow)
if [[ $ROOT_PW -eq 1 ]]; then
    echo "\u10003 proxmox server has non-default root password"
else
    echo "\u26A0 proxmox server has default root password"
fi

echo "\u11118 checking if proxmox server has non-default pveadmin password..."
PVEADMIN_PW=$(grep -c 'pveadmin:$6$' /etc/shadow)
if [[ $PVEADMIN_PW -eq 1 ]]; then
    echo "\u10003 proxmox server has non-default pveadmin password"
else
    echo "\u26A0 proxmox server has default pveadmin password"
fi

echo "\u11118 checking if proxmox server has non-default www-data password..."
WWW_DATA_PW=$(grep -c 'www-data:$6$' /etc/shadow)
if [[ $WWW_DATA_PW -eq 1 ]]; then
    echo "\u10003 proxmox server has non-default www-data password"
else
    echo "\u26A0 proxmox server has default www-data password"
fi

echo "\u11118 checking if proxmox server has SSH root login disabled..."
SSH_ROOT_LOGIN=$(grep -c 'PermitRootLogin no' /etc/ssh/sshd_config)
if [[ $SSH_ROOT_LOGIN -eq 1 ]]; then
    echo "\u10003 proxmox server has SSH root login disabled"
else
    echo "\u2713 proxmox server has SSH root login enabled"
fi

echo "\u11118 checking if proxmox server has firewall enabled..."
FIREWALL_STATUS=$(systemctl is-active pve-firewall)
if [[ $FIREWALL_STATUS == "active" ]]; then
    echo "\u10003 proxmox server has firewall enabled"
else
    echo "\u2713 proxmox server has firewall disabled"
fi

echo "\u11118 checking if proxmox server has SELinux or AppArmor enabled..."
SELINUX_STATUS=$(getenforce)
APPARMOR_STATUS=$(apparmor_status | grep -c "apparmor module is loaded")
if [[ $SELINUX_STATUS == "Enforcing" || $APPARMOR_STATUS -eq 1 ]]; then
    echo "\u10003 proxmox server has SELinux or AppArmor enabled"
else
    echo "\u2713 proxmox server has SELinux or AppArmor disabled"
fi

echo "Hardening checks completed"

#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ $# -ne 2 ]; then
    echo "Usage: $0 <vmid> </path/to/iso>"
    exit 1
fi

vmid=$1
iso=$2

echo "Creating VM..."
qm create $vmid --name kali --ostype l26 --ide2 local:iso/$(basename $iso),media=cdrom

echo "Starting VM..."
qm start $vmid

sleep 10

echo "Installing and configuring Tor..."
qm terminal $vmid << EOF
apt-get update
apt-get install tor -y
sed -i 's/#ControlPort 9051/ControlPort 9051/' /etc/tor/torrc
sed -i 's/#CookieAuthentication 1/CookieAuthentication 1/' /etc/tor/torrc
systemctl restart tor
EOF

echo "Installing torify and proxychains..."
qm terminal $vmid << EOF
apt-get install torify proxychains -y
EOF

echo "Isolating VM..."
echo "cpu: host,hidden=1" >> /etc/pve/qemu-server/$vmid.conf
echo "args: -cpu 'host,-hypervisor'" >> /etc/pve/qemu-server/$vmid.conf

echo "Hardening VM..."
qm terminal $vmid << EOF
apt-get install aide rkhunter chkrootkit -y
apt-get update && apt-get upgrade -y
passwd
EOF

echo "Creating golden image..."
vzdump $vmid --mode stop --compress lzo --storage local

echo "VM deployment completed"

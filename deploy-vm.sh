#!/bin/bash

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Check for arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <vmid> </path/to/iso>"
    exit 1
fi

vmid=$1
iso=$2

# Create VM
echo "Creating VM..."
qm create $vmid --name kali --ostype l26 --ide2 local:iso/$(basename $iso),media=cdrom

# Start VM
echo "Starting VM..."
qm start $vmid

# Wait for VM to start
sleep 10

# Install and configure Tor
echo "Installing and configuring Tor..."
qm terminal $vmid << EOF
apt-get update
apt-get install tor -y
sed -i 's/#ControlPort 9051/ControlPort 9051/' /etc/tor/torrc
sed -i 's/#CookieAuthentication 1/CookieAuthentication 1/' /etc/tor/torrc
systemctl restart tor
EOF

# Install torify and proxychains
echo "Installing torify and proxychains..."
qm terminal $vmid << EOF
apt-get install torify proxychains -y
EOF

# Isolate VM
echo "Isolating VM..."
echo "cpu: host,hidden=1" >> /etc/pve/qemu-server/$vmid.conf
echo "args: -cpu 'host,-hypervisor'" >> /etc/pve/qemu-server/$vmid.conf

# Harden VM
echo "Hardening VM..."
qm terminal $vmid << EOF
apt-get install aide rkhunter chkrootkit -y
apt-get update && apt-get upgrade -y
passwd
EOF

# Create golden image
echo "Creating golden image..."
vzdump $vmid --mode stop --compress lzo --storage local

echo "VM deployment completed"

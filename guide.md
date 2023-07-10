# Deploy an Ephemeral Linux VM for Web Browsing (very much in process)

## 1. Update Proxmox Server

```bash
apt-get update && apt-get dist-upgrade -y && reboot
```
<br>

## 2. Create a New VM
First, upload your Linux ISO to the server. Replace </path/to/your.iso> with the actual path to your ISO file.

```bash
pvesm alloc /var/lib/vz/template/iso your.iso --size $(du -b </path/to/your.iso> | cut -f1)
dd if=</path/to/your.iso> of=</var/lib/vz/template/iso/your.iso>
```
Then, create a new VM. Replace VMID with a unique VM ID number, and storid with your storage ID.

```bash
qm create <VMID> --name kali --ostype l26 --ide2 <storid>:iso/<your.iso>,media=cdrom
```
<br>

## 3. Install and Configure Tor or VPN

Use the following commands to install and configure it from the guest virtual machine:
```bash
apt-get update && apt-get install tor -y
sed -i 's/#ControlPort 9051/ControlPort 9051/' /etc/tor/torrc
sed -i 's/#CookieAuthentication 1/CookieAuthentication 1/' /etc/tor/torrc
systemctl restart tor
```

<br>

## 4. Route All Traffic Through Tor or VPN

Use torify or proxychains to route your traffic, run this from the guest virtual machine:
```bash
apt-get install torify proxychains -y
```

<br>

## 5. Isolate the VM
To isolate the VM network, you will need to create a separate network bridge for the VM. Since traffic routing will be done at the guest-level, I would advise against routing this through a VPN.

To isolate the VM from the host and other VMs, you can use cgroups and namespaces. This can be done by editing the VM's configuration file and adding the following lines on the Proxmox host:

```bash
echo "cpu: host,hidden=1" >> /etc/pve/qemu-server/<VMID>.conf
echo "args: -cpu 'host,-hypervisor'" >> /etc/pve/qemu-server/<VMID>.conf
```

<br>

## 6. Create a Golden Image (backup)

Once everything is set up and configured, you can create a golden image of the VM on the Proxmox host. Your image file can be found in /var/lib/vz/dump/ and can be used to create new VMs with the same configuration and settings

```bash
vzdump <VMID> --mode stop --compress lzo --storage <storid>
ls /var/lib/vz/dump/
```


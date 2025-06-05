# Ubuntu autoinstall

# WORK IN PROGRESS WIP

A homelab setup for network boot and Ubuntu server / desktop autoinstall

I want to set up a system that allows booting computers over the network and automatically installing Ubuntu Server or Desktop.

## My setup

To experiment with this kind of setup, you’ll need a Linux computer with two network interfaces (referred to as “the router”) and one or more computers that will be installed (referred to as “the clients”).

The main idea is to isolate the client's network and have the Linux router provide all necessary services (such as DHCP, TFTP, etc.) without interfering with your existing local network (where you already have a DHCP server).

The easiest way is to use a Linux laptop with both wireless and wired interfaces — this will act as the router. In my setup, the clients are older (Gen 5 / Gen 7) Intel NUC mini-computers.

```
      ^internet connection
     /
    /wlan
  +---------         +-----------+ 
  | Linux  |eth0     | optional  |
  | laptop +---------+ unmanaged +--- NUC1
  |        |         | switch    +--- NUC2
  +--------+         +-----------+
```

If you don't have a switch, you can connect a single client directly to the laptop’s wired interface.

Another option, with a Linux router with a single network interface but with a managed switch, with VLANs is described in the file [vlans-setup.md](vlans-setup.md).

## First steps

Work in terminal, on the Linux router. Clone this repo. In all instructions I'm assuming 
you are running all commands as *ROOT* under `/root` directory. 
From regular user just run `sudo su -` to ensure that.

## Interfaces, ip_forward and firewall

Check your network interfaces with `ifconfig`. I'm old school and I prefer that to the newer `ip a`, so install the `net-tools` package if you don't already have it.

Presumably the wireless interface is already configured and you have access to the internet, we'll don't touch that. The wired interface is called in my case **enp3s0** and is unconfigured. I'm choosing a static IP address for that: **192.168.10.1**. Pick your own to avoid conflicts with your local network(s) but remember to replace it everywhere in config files where you see **192.168.10*.

Now you need to
- setup the static IP 192.168.10.1 on wired interface
- enable ip_forward - that's will transform your Linux in a router, enabling packets routing between interfaces
- (optional) set IP masquerading to make packets from clients go out on the wireless interface with the same IP as the wifi one

One way to do that would be:

```
# set the IP on wired interface  
ifconfig enp3s0 192.168.10.1 netmask 255.255.255.0 up

# enable ip_forward
echo "1" > /proc/sys/net/ipv4/ip_forward  
# edit /etc/sysctl.conf to make it persistent

# setup masquerading
iptables -t nat -I POSTROUTING \! -o enp3s0 -s 192.168.10.0/24 -j MASQUERADE
# packets which go out on an interface different than enp3s0 and have the source 192.168.10.0/24 will be masqueraded
# with the IP from - in this case - wifi interface
```

You will need to somehow make those settings persistent. I'm leaving in this repo some example firewall files which can help.

## Simple http server

Install nginx (`apt install nginx`) and copy the files from this repo var_www_html into `/var/www/html/`. 
Some of them will need to be ajusted and I'll discuss them below.

Download the necessary ISO files under `/var/www/html/iso/`.

## DHCP server

Install it with `apt install isc-dhcp-server`. Edit `/etc/default/isc-dhcp-server` 
and make sure it listens only on wired interface. That file has at the end:

```
# On what interfaces should the DHCP server (dhcpd) serve DHCP requests?
#       Separate multiple interfaces with spaces, e.g. "eth0 eth1".
INTERFACESv4="enp0s3"
INTERFACESv6=""
```

Adjust the dhcpd.conf file form this repo for your case. Then restart and check the dhcpd:

```
systemctl enable  isc-dhcp-server
systemctl restart isc-dhcp-server
systemctl status  isc-dhcp-server
```

## TFTP server

Install packages: `apt install tftpd-hpa pxelinux syslinux-common`. 

Edit `/etc/default/tftpd-hpa` and make it like the one in this repo.

Copy some files under the tftp root directory:

```
mkdir -p /srv/tftp

cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp
cp /usr/lib/syslinux/modules/bios/menu.c32 /srv/tftp/

mkdir /srv/tftp/pxelinux.cfg
```

The main configuration file for boot from network is `/srv/tftp/pxelinux.cfg/default`, copy it from this repo `pxelinux-default`.

Restart and status the tftp server.

## More files for tftp boot

Reading the `/srv/tftp/pxelinux.cfg/default` you will see you will need:
- for `KERNEL ubuntu-server/amd64/linux` - a Linux kernel at the location `/srv/tftp/ubuntu-server/amd64/linux`
- for `APPEND initrd=ubuntu-desktop/amd64/initrd.gz` - initrd file at `/srv/tftp/ubuntu-server/amd64/initrd.gz`
- for `url=http://192.168.10.1/iso/ubuntu-24.04.1-live-server-amd64.iso` - the iso file under `/var/www/html/iso/`
- for `http://192.168.10.1/autoinstall-server.yaml` - the file under `/var/www/html/autoinstall-server.yaml`

For the kernel and initrd files, you will need to copy those from the ISO image:
```
# example for ubuntu server
mkdir -p /srv/tftp/ubuntu-server/amd64/linux

mount -o loop /var/www/html/iso/ubuntu-24.04.1-live-server-amd64.iso /mnt
cp /mnt/casper/vmlinuz /srv/tftp/ubuntu-installer/amd64/linux
cp /mnt/casper/initrd  /srv/tftp/ubuntu-installer/amd64/initrd.gz
umount /mnt
```

DO NOT mix kernel/initrd from other ISO-s (from server to desktop or from ubuntu-24.04.2 to ubuntu-24.04.1 etc)!!!

## How to network boot the clients

On Intel NUC Gen 7, trying to **press F12 to network boot** will fail with this setup!!! 
ChatGPT can explain why, it's related to UEFI vs Legacy BIOS etc. But for now, just leave the Intel NUC without any other boot option. 

For example you can erase the boot disk beginning:

```
# this is what to run on a Intel NUC with Linux to leave it without OS
# it will overwrite with 0 the first 2MB on nvme disk
dd if=/dev/zero of=/dev/nvme0n1 bs=1M count=2
reboot
```

## Optional http proxy (squid) and apt proxy



  



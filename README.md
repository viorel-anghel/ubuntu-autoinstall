# Ubuntu autoinstall

# WORK IN PROGRESS WIP

A homelab setup for network boot and Ubuntu server / desktop autoinstall

## What I want to have

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

Another option, with a Linux router with a single network interface but with managed switch, with VLANs is described in the file [vlans-setup.md](vlans-setup.md).

## First steps

Work in terminal, on the Linux router. Clone this repo. In all instructions I'm assuming 
you are running all commands as *ROOT* under `/root` directory. 
From regular user just run `sudo su -` to ensure that.

## Interfaces, ip_forward and firewall

Check your network interfaces with `ifconfig`. I'm old school and I preffer that to newer `ip a`, install `net-tools` package if you don't have it.

Presumably the wireless interface is already configured and you have access to the internet, we'll don't touch that. The wired interface is called in my case `enp3s0` and is unconfigured. 





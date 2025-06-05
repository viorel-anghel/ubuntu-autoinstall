#/bin/bash
# file /usr/local/bin/firewall.sh

export PATH=/sbin:/usr/sbin:/bin:/usr/bin

WAN=wl01
LAN=enp0s3

# setup wired interface here if needed
ifconfig $LAN 192.168.10.1 netmask 255.255.255.0 up 

# Flush all rules, delete all chains, and accept all by default
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Allow loopback interface
iptables -A INPUT -i lo -j ACCEPT

# Allow ICMP
iptables -A INPUT -p icmp -j ACCEPT

# Allow established and related incoming connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow dhcp client
iptables -A INPUT -p udp --sport 67 --dport 68 -j ACCEPT

# Allow tcp ports from any
for p in 22 10022
do
  iptables -A INPUT -p tcp --dport $p -j ACCEPT
done

### special - allow any on wired interface and masquerade
iptables -A INPUT   -i $LAN -j ACCEPT
iptables -A FORWARD -i $LAN -j ACCEPT
iptables -t nat -A POSTROUTING \! -o $LAN -s 192.168.10.0/24 -j MASQUERADE

# Close the gate Reject all inputs
iptables -A INPUT   -m state --state NEW -j LOG
iptables -A INPUT   -m state --state NEW -j DROP
iptables -A FORWARD -m state --state NEW -j LOG
iptables -A FORWARD -m state --state NEW -j DROP



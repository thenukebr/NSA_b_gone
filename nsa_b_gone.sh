#!/bin/bash
# Firewall apps - only allow apps run from "internet" group to run

# Interfaces
#LAN=eth0
LAN=wlan0

# Clear all chains
echo "Setting up firewall..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

# set the default policy
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

#create internet group - this only needs to happen once
# groupadd internet

# accept WLAN traffic based on established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# accept packets for internet group
iptables -A OUTPUT -p tcp -m owner --gid-owner internet -j ACCEPT

# allow localhost
iptables -I INPUT -i lo -j ACCEPT
iptables -I OUTPUT -p tcp -d 127.0.0.1 -j ACCEPT

# drop packets for other users
iptables -A OUTPUT -p tcp -d 192.168.0.1/24 -j ACCEPT
iptables -A OUTPUT -p tcp -j REJECT

# Stop networking service, so that we can re-configure the MAC address
echo "Setting up the new MAC address..."
service network-manager stop

# mac address randomisation
NEWMAC=`echo $RANDOM$RANDOM | md5sum | sed -r 's/(..)/\1:/g; s/^(.{14}).*$/\1/;'`
NEWMAC="a8:$NEWMAC" # first byte has to be even
ifconfig "$LAN" down hw ether $NEWMAC
ifconfig "$LAN" up
echo "New MAC address: $NEWMAC"

# restart networking services
echo "Waiting for network restart..."
service network-manager start
# now wait for networking to start up
sleep 2s

# hostname randomization
NEWHOST=`tr -dc A-Za-z0-9 < /dev/urandom |head -c 12`
/bin/hostname "$NEWHOST"
echo "127.0.0.1 $NEWHOST" >> /etc/hosts
echo "New hostname: $NEWHOST"

# open a shell with internet access
#sudo -g internet -s

echo "Done."
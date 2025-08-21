#!/bin/bash

set -e

# Check and set interfaces
WAN_IF=$(ip -o -4 route show to default | awk '{print $5}')
LAN_IF=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | grep -v "$WAN_IF" | head -n1)

echo "WAN interface: $WAN_IF"
echo "LAN interface: $LAN_IF"

# Check and set IP forwarding
IPF=$(sysctl -n net.ipv4.ip_forward)
if [ "$IPF" -eq 1 ]; then
    echo "IP forwarding enabled"
else
    echo "Enabling IP forwarding..."
    if ! grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    fi
    sudo sysctl -p
fi

# Interfaces to zones
sudo firewall-cmd --permanent --zone=public --change-interface=$WAN_IF
sudo firewall-cmd --permanent --zone=internal --change-interface=$LAN_IF

# Add masquerade to WAN
sudo firewall-cmd --permanent --zone=public --add-masquerade

# Policies internal -> public
sudo firewall-cmd --permanent --new-policy internal-to-public || true
sudo firewall-cmd --permanent --policy internal-to-public --set-target ACCEPT
sudo firewall-cmd --permanent --policy internal-to-public --add-ingress-zone internal
sudo firewall-cmd --permanent --policy internal-to-public --add-egress-zone public

# 5. reload firewalld
sudo firewall-cmd --reload

echo "Done"

#!/bin/bash
set -euo pipefail

# Connection names from your router
EXT_CONN="external-net"
A_CONN="subnet-A"
B_CONN="subnet-B"
S_CONN="subnet-S"

systemctl enable --now firewalld

# Bind zones via NetworkManager (persistent)
nmcli connection modify "$EXT_CONN" connection.zone public
nmcli connection modify "$A_CONN" connection.zone trusted
nmcli connection modify "$B_CONN" connection.zone trusted
nmcli connection modify "$S_CONN" connection.zone trusted

nmcli connection down "$EXT_CONN" && nmcli connection up "$EXT_CONN"
nmcli connection down "$A_CONN" && nmcli connection up "$A_CONN"
nmcli connection down "$B_CONN" && nmcli connection up "$B_CONN"
nmcli connection down "$S_CONN" && nmcli connection up "$S_CONN"

# NAT only on public
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --permanent --zone=trusted --remove-masquerade || true
firewall-cmd --reload

# Enable routing
sysctl -w net.ipv4.ip_forward=1 >/dev/null
grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

echo "OK: Router firewall configured (zones + NAT only on uplink + ip_forward)"

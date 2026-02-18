#!/bin/bash
set -euo pipefail

ZONE="public"
CLIENT_A_SUBNET="172.16.20.0/24"
CLIENT_B_SUBNET="172.16.30.0/24"

systemctl enable --now firewalld

# Default deny
firewall-cmd --permanent --zone="$ZONE" --set-target=DROP

# Remove global exposure
firewall-cmd --permanent --zone="$ZONE" --remove-service=http || true
firewall-cmd --permanent --zone="$ZONE" --remove-service=https || true

# Allow Client A only (HTTP+HTTPS)
firewall-cmd --permanent --zone="$ZONE" \
  --add-rich-rule="rule family=\"ipv4\" source address=\"$CLIENT_A_SUBNET\" port port=\"80\" protocol=\"tcp\" accept"

firewall-cmd --permanent --zone="$ZONE" \
  --add-rich-rule="rule family=\"ipv4\" source address=\"$CLIENT_A_SUBNET\" port port=\"443\" protocol=\"tcp\" accept"

# Optional explicit drop for Client B (not required if target DROP)
firewall-cmd --permanent --zone="$ZONE" \
  --add-rich-rule="rule family=\"ipv4\" source address=\"$CLIENT_B_SUBNET\" port port=\"80\" protocol=\"tcp\" drop" || true

firewall-cmd --permanent --zone="$ZONE" \
  --add-rich-rule="rule family=\"ipv4\" source address=\"$CLIENT_B_SUBNET\" port port=\"443\" protocol=\"tcp\" drop" || true

firewall-cmd --reload

echo "OK: Main server firewall configured (allow A, block B, default DROP)"


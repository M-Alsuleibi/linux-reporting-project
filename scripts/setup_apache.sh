#!/bin/bash
set -euo pipefail

WEB_ROOT="/var/www/html"
STATUS_FILE="$WEB_ROOT/status.html"

echo "[setup_apache] Installing and enabling Apache..."
sudo dnf install -y httpd
sudo systemctl enable --now httpd

echo "[setup_apache] Ensuring web root exists..."
sudo mkdir -p "$WEB_ROOT"

# Create status.html if missing (permissions handled by setup_user_and_perms.sh later)
if [ ! -f "$STATUS_FILE" ]; then
  echo "[setup_apache] Creating empty $STATUS_FILE"
  sudo touch "$STATUS_FILE"
fi

echo "[setup_apache] Done."
sudo systemctl is-active httpd

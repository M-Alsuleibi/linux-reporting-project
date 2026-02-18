#!/bin/bash
set -euo pipefail

REPORT_USER="reporter"
REPORT_GROUP="reporter"
WEB_DIR="/var/www/html"
STATUS_FILE="$WEB_DIR/status.html"
METRICS_DIR="/mnt/metrics"
BACKUPS_DIR="/backups"

# 1) Create system user if missing
if ! id "$REPORT_USER" &>/dev/null; then
  useradd -r -s /sbin/nologin "$REPORT_USER"
fi

# 2) Ensure dirs exist
mkdir -p "$METRICS_DIR" "$BACKUPS_DIR"
chmod 755 "$METRICS_DIR" "$BACKUPS_DIR"
chown -R "$REPORT_USER:$REPORT_GROUP" "$METRICS_DIR" "$BACKUPS_DIR"

# 3) Ensure status file exists with safe perms
# We do NOT change ownership of /var/www/html globally.
touch "$STATUS_FILE"
chown root:"$REPORT_GROUP" "$STATUS_FILE"
chmod 664 "$STATUS_FILE"

# 4) If SELinux is enforcing, ensure Apache can read it
if command -v getenforce &>/dev/null; then
  if [ "$(getenforce)" = "Enforcing" ]; then
    # restore correct context for web files
    restorecon -v "$STATUS_FILE" || true
  fi
fi

echo "OK: user/perms configured (reporter, metrics, backups, status.html)"

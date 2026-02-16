#!/bin/bash
set -e

CRON_SRC="/opt/linux-reporting-project/config/cron/linux-reporting-project.cron"
CRON_DST="/etc/cron.d/linux-reporting-project"
LOG_DIR="/var/log/linux-reporting-project"

# Ensure crond is enabled and running
systemctl enable --now crond

# Ensure log directory exists
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# Install cron file
if [ ! -f "$CRON_SRC" ]; then
  echo "Error: cron source file not found at $CRON_SRC"
  exit 1
fi

cp "$CRON_SRC" "$CRON_DST"
chmod 644 "$CRON_DST"

echo "Installed cron job file to $CRON_DST"

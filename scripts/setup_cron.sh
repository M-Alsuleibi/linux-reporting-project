#!/bin/bash
set -e

CRON_SRC="/opt/linux-reporting-project/config/cron/linux-reporting-project.cron"
CRON_DST="/etc/cron.d/linux-reporting-project"
LOG_DIR="/var/log/linux-reporting-project"
RUN_USER="reporter"

# Ensure crond is enabled and running
systemctl enable --now crond

# Validate reporter user exists
if ! id "$RUN_USER" &>/dev/null; then
  echo "Error: user '$RUN_USER' does not exist. Run setup_user_and_perms.sh first."
  exit 1
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"
# Assign ownership to reporter
chown "$RUN_USER":"$RUN_USER" "$LOG_DIR
chmod 755 "$LOG_DIR"

# Install cron file
if [ ! -f "$CRON_SRC" ]; then
  echo "Error: cron source file not found at $CRON_SRC"
  exit 1
fi

cp "$CRON_SRC" "$CRON_DST"
chmod 644 "$CRON_DST"

echo "Installed cron job file to $CRON_DST"

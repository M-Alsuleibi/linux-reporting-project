#!/bin/bash
set -euo pipefail

REPORT_USER="reporter"
WEB_ROOT="/var/www"
HTML_ROOT="$WEB_ROOT/html"
STATUS_FILE="$HTML_ROOT/status.html"
HTTPD_CONF="/etc/httpd/conf/httpd.conf"

dnf install -y httpd

mkdir -p "$HTML_ROOT"
chown -R "$REPORT_USER:$REPORT_USER" "$WEB_ROOT"

sed -i \
  -e "s/^User .*/User $REPORT_USER/" \
  -e "s/^Group .*/Group $REPORT_USER/" \
  "$HTTPD_CONF"

touch "$STATUS_FILE"
chown "$REPORT_USER:$REPORT_USER" "$STATUS_FILE"

systemctl enable --now httpd
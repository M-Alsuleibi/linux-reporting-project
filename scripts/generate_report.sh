#!/bin/bash
set -euo pipefail

dnf install -y bc procps-ng iproute 2>/dev/null || true

HOSTNAME=$(hostname)
IP_ADDRESS=$(ip -4 addr show ens160 | awk '/inet / {print $2}' | cut -d/ -f1)
CURRENT_TIME=$(date)
CPU_IDLE=$(top -bn1 | awk -F',' '/Cpu\(s\)/ {print $4}' | awk '{print $1}')
CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc)
MEM_TOTAL_MB=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED_MB=$(free -m | awk '/^Mem:/ {print $3}')
MEM_USED_PCT=$(awk -v used="$MEM_USED_MB" -v total="$MEM_TOTAL_MB" 'BEGIN { printf "%.1f", (used/total)*100 }')
DISK_ROOT=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

if mountpoint -q /mnt/metrics; then
  DISK_METRICS=$(df -h /mnt/metrics | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
else
  DISK_METRICS="Not mounted"
fi

TOP_PROCS=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5)

WEB_ROOT="/var/www/html"
REPORT_PATH="$WEB_ROOT/status.html"
METRICS_DIR="/mnt/metrics"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# ---- Backup previous report  ----

if [ -f "$REPORT_PATH" ]; then
    if mountpoint -q "$METRICS_DIR"; then
        cp "$REPORT_PATH" "$METRICS_DIR/status-$TIMESTAMP.html"
        echo "Previous report archived to $METRICS_DIR"
    else
        echo "Warning: $METRICS_DIR not mounted. Skipping archive."
    fi
fi


echo "Generating system report..."

echo "<html>" > $REPORT_PATH
echo "<head><title>System Status</title></head>" >> $REPORT_PATH
echo "<body>" >> $REPORT_PATH
echo "<h1>System Report</h1>" >> $REPORT_PATH

echo "<h2>Hostname</h2>" >> $REPORT_PATH
echo "<p>$HOSTNAME</p>" >> $REPORT_PATH

echo "<h2>IP Address</h2>" >> $REPORT_PATH
echo "<p>$IP_ADDRESS</p>" >> $REPORT_PATH

echo "<h2>Current Time</h2>" >> $REPORT_PATH
echo "<p>$CURRENT_TIME</p>" >> $REPORT_PATH

echo "<h2>CPU Usage</h2>" >> $REPORT_PATH
echo "<p>${CPU_USAGE}%</p>" >> $REPORT_PATH

echo "<h2>Memory Usage</h2>" >> $REPORT_PATH
echo "<p>Used: ${MEM_USED_MB} MB / ${MEM_TOTAL_MB} MB (${MEM_USED_PCT}%)</p>" >> $REPORT_PATH

echo "<h2>Disk Usage</h2>" >> $REPORT_PATH
echo "<p><b>/</b>: $DISK_ROOT</p>" >> $REPORT_PATH
echo "<p><b>/mnt/metrics</b>: $DISK_METRICS</p>" >> $REPORT_PATH

echo "<h2>Top 5 Processes (by CPU)</h2>" >> "$REPORT_PATH"
echo "<table border=\"1\" cellpadding=\"6\" cellspacing=\"0\">" >> "$REPORT_PATH"
echo "<tr><th>PID</th><th>User</th><th>CPU%</th><th>MEM%</th><th>Command</th></tr>" >> "$REPORT_PATH"

while read -r PID USER CPU MEM CMD; do
  echo "<tr><td>$PID</td><td>$USER</td><td>$CPU</td><td>$MEM</td><td>$CMD</td></tr>" >> "$REPORT_PATH"
done <<< "$TOP_PROCS"

echo "</table>" >> "$REPORT_PATH"

echo "</body>" >> $REPORT_PATH

echo "</html>" >> $REPORT_PATH

echo "Report generated at $REPORT_PATH"

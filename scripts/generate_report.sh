#!/bin/bash
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

OUTPUT="/var/www/html/status.html"

echo "Generating system report..."

echo "<html>" > $OUTPUT
echo "<head><title>System Status</title></head>" >> $OUTPUT
echo "<body>" >> $OUTPUT
echo "<h1>System Report</h1>" >> $OUTPUT

echo "<h2>Hostname</h2>" >> $OUTPUT
echo "<p>$HOSTNAME</p>" >> $OUTPUT

echo "<h2>IP Address</h2>" >> $OUTPUT
echo "<p>$IP_ADDRESS</p>" >> $OUTPUT

echo "<h2>Current Time</h2>" >> $OUTPUT
echo "<p>$CURRENT_TIME</p>" >> $OUTPUT

echo "<h2>CPU Usage</h2>" >> $OUTPUT
echo "<p>${CPU_USAGE}%</p>" >> $OUTPUT

echo "<h2>Memory Usage</h2>" >> $OUTPUT
echo "<p>Used: ${MEM_USED_MB} MB / ${MEM_TOTAL_MB} MB (${MEM_USED_PCT}%)</p>" >> $OUTPUT

echo "<h2>Disk Usage</h2>" >> $OUTPUT
echo "<p><b>/</b>: $DISK_ROOT</p>" >> $OUTPUT
echo "<p><b>/mnt/metrics</b>: $DISK_METRICS</p>" >> $OUTPUT

echo "<h2>Top 5 Processes (by CPU)</h2>" >> "$OUTPUT"
echo "<table border=\"1\" cellpadding=\"6\" cellspacing=\"0\">" >> "$OUTPUT"
echo "<tr><th>PID</th><th>User</th><th>CPU%</th><th>MEM%</th><th>Command</th></tr>" >> "$OUTPUT"

while read -r PID USER CPU MEM CMD; do
  echo "<tr><td>$PID</td><td>$USER</td><td>$CPU</td><td>$MEM</td><td>$CMD</td></tr>" >> "$OUTPUT"
done <<< "$TOP_PROCS"

echo "</table>" >> "$OUTPUT"

echo "</body>" >> $OUTPUT

echo "</html>" >> $OUTPUT

echo "Report generated at $OUTPUT"

#!/bin/bash
set -euo pipefail

echo "[run] Starting server setup..."

./scripts/setup_mount_metrics.sh
./scripts/setup_apache.sh
./scripts/setup_ssl.sh
./scripts/setup_firewall_main.sh
./scripts/setup_cron.sh

echo "[run] Running initial report as reporter..."
sudo -u reporter ./scripts/generate_report.sh

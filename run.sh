#!/bin/bash
set -euo pipefail

REPO_DIR="/opt/linux-reporting-project"
cd "$REPO_DIR"

echo "[run] Starting server setup..."
./scripts/setup_user.sh
./scripts/setup_mount_metrics.sh
./scripts/setup_apache.sh
./scripts/setup_ssl.sh
./scripts/setup_cron.sh

echo "[run] Running initial report as reporter..."
sudo -u reporter ./scripts/generate_report.sh

echo "Setup complete."
echo "  curl http://localhost/status.html"
echo "  curl -k https://localhost/status.html"
#!/bin/bash
set -euo pipefail

ROLE="${1:-}"

if [ -z "$ROLE" ]; then
  echo "Usage:"
  echo "  sudo ./run.sh server"
  echo "  sudo ./run.sh router"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: run as root (sudo)."
  exit 1
fi

REPO_DIR="/opt/linux-reporting-project"

if [ ! -d "$REPO_DIR/scripts" ]; then
  echo "Error: expected repo at $REPO_DIR"
  echo "Clone it first to /opt/linux-reporting-project"
  exit 1
fi

cd "$REPO_DIR"

if [ "$ROLE" = "server" ]; then
  echo "[run] Role=server"

  ./scripts/setup_packages_server.sh
  ./scripts/setup_mount_metrics.sh
  ./scripts/setup_user_and_perms.sh
  ./scripts/setup_apache.sh
  ./scripts/setup_ssl.sh
  ./scripts/setup_firewall_main.sh
  ./scripts/setup_cron.sh

  echo "[run] Server setup complete."
  echo "[run] Quick manual checks:"
  echo "  sudo -u reporter ./scripts/generate_report.sh"
  echo "  curl http://<server-ip>/status.html"
  echo "  curl -k https://<server-ip>/status.html"

elif [ "$ROLE" = "router" ]; then
  echo "[run] Role=router"

  # Router packages: firewalld + NetworkManager tools should already exist on Rocky,
  # but install firewalld to be safe.
  dnf install -y firewalld NetworkManager
  systemctl enable --now firewalld

  ./scripts/setup_firewall_router.sh

  echo "[run] Router setup complete."
  echo "[run] Verify:"
  echo "  sysctl net.ipv4.ip_forward"
  echo "  firewall-cmd --get-active-zones"

else
  echo "Unknown role: $ROLE"
  exit 1
fi

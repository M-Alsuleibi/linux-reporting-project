#!/bin/bash
set -euo pipefail

echo "[setup_packages_server] Installing required packages..."

sudo dnf install -y \
  git \
  httpd \
  mod_ssl \
  openssl \
  firewalld \
  cronie \
  bc \
  tar \
  util-linux \
  procps-ng \
  iproute

echo "[setup_packages_server] Enabling services..."
sudo systemctl enable --now firewalld
sudo systemctl enable --now httpd
sudo systemctl enable --now crond

echo "[setup_packages_server] Done."

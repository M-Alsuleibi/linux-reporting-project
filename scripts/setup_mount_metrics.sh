#!/bin/bash
set -euo pipefail

MOUNTPOINT="/mnt/metrics"

echo "[setup_mount_metrics] Ensuring mountpoint exists..."
sudo mkdir -p "$MOUNTPOINT"

# If already mounted, just confirm and exit
if mountpoint -q "$MOUNTPOINT"; then
  echo "[setup_mount_metrics] $MOUNTPOINT is already mounted."
  df -h "$MOUNTPOINT" || true
  exit 0
fi

# Detect a likely candidate: largest non-root disk partition not used for / or /boot
# This is best-effort. If it fails, user must pass DEVICE explicitly.
CANDIDATE="$(
  lsblk -pnro NAME,TYPE,MOUNTPOINT,SIZE |
  awk '$2=="part" && $3=="" {print $1" "$4}' |
  sort -k2 -h |
  tail -n 1 |
  awk '{print $1}'
)"

if [ -z "$CANDIDATE" ] || [ ! -b "$CANDIDATE" ]; then
  echo "[setup_mount_metrics] Could not auto-detect metrics device."
  echo "Run: lsblk -f"
  echo "Then rerun with: METRICS_DEVICE=/dev/<your-partition> sudo -E ./scripts/setup_mount_metrics.sh"
  exit 1
fi

DEVICE="${METRICS_DEVICE:-$CANDIDATE}"

if [ ! -b "$DEVICE" ]; then
  echo "[setup_mount_metrics] Device not found: $DEVICE"
  exit 1
fi

# Require filesystem present (we do NOT format here)
FSTYPE="$(sudo blkid -o value -s TYPE "$DEVICE" 2>/dev/null || true)"
UUID="$(sudo blkid -o value -s UUID "$DEVICE" 2>/dev/null || true)"

if [ -z "$FSTYPE" ] || [ -z "$UUID" ]; then
  echo "[setup_mount_metrics] ERROR: $DEVICE has no filesystem/UUID."
  echo "Format it manually first (ext4 recommended), then rerun."
  exit 1
fi

echo "[setup_mount_metrics] Mounting $DEVICE ($FSTYPE, UUID=$UUID) to $MOUNTPOINT..."
sudo mount "$DEVICE" "$MOUNTPOINT"

# Persist in fstab if not already present
if ! grep -q "UUID=$UUID" /etc/fstab; then
  echo "[setup_mount_metrics] Adding fstab entry..."
  echo "UUID=$UUID  $MOUNTPOINT  $FSTYPE  defaults,nofail  0  2" | sudo tee -a /etc/fstab >/dev/null
else
  echo "[setup_mount_metrics] fstab already has entry for UUID=$UUID"
fi

echo "[setup_mount_metrics] Done."
df -h "$MOUNTPOINT" || true

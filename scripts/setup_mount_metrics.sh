#!/bin/bash
set -euo pipefail

BASE_DEVICE="/dev/nvme0n2"
MOUNTPOINT="/mnt/metrics"
FSTYPE_EXPECTED="xfs"

echo "[setup_mount_metrics] Ensuring mountpoint exists..."
sudo mkdir -p "$MOUNTPOINT"

# If already mounted, confirm and exit
if mountpoint -q "$MOUNTPOINT"; then
  echo "[setup_mount_metrics] $MOUNTPOINT is already mounted."
  df -h "$MOUNTPOINT"
  exit 0
fi

# Verify base device exists
if [ ! -b "$BASE_DEVICE" ]; then
  echo "[setup_mount_metrics] Base device not found: $BASE_DEVICE"
  exit 1
fi

# Auto-detect the first partition on the device (e.g. nvme0n2p1)
DEVICE="$(lsblk -pnro NAME,TYPE "$BASE_DEVICE" | awk '$2=="part" {print $1; exit}')"

if [ -z "$DEVICE" ] || [ ! -b "$DEVICE" ]; then
  echo "[setup_mount_metrics] No partition found on $BASE_DEVICE."
  echo "Creating partition automatically..."
  echo -e "g\nn\n1\n\n\nw" | sudo fdisk "$BASE_DEVICE"
  # Re-read partition table
  sudo partprobe "$BASE_DEVICE"
  sleep 2
  DEVICE="$(lsblk -pnro NAME,TYPE "$BASE_DEVICE" | awk '$2=="part" {print $1; exit}')"
fi

echo "[setup_mount_metrics] Using partition: $DEVICE"

# Format with XFS only if no filesystem exists
CURRENT_FSTYPE="$(sudo blkid -o value -s TYPE "$DEVICE" 2>/dev/null || true)"

if [ -z "$CURRENT_FSTYPE" ]; then
  echo "[setup_mount_metrics] No filesystem detected. Formatting $DEVICE with $FSTYPE_EXPECTED..."
  sudo mkfs.xfs "$DEVICE"
elif [ "$CURRENT_FSTYPE" != "$FSTYPE_EXPECTED" ]; then
  echo "[setup_mount_metrics] WARNING: $DEVICE already has filesystem: $CURRENT_FSTYPE (expected $FSTYPE_EXPECTED)"
  echo "Aborting to avoid data loss. Wipe manually if intended: sudo wipefs -a $DEVICE"
  exit 1
else
  echo "[setup_mount_metrics] $DEVICE already formatted as $FSTYPE_EXPECTED. Skipping format."
fi

# Grab UUID after format
UUID="$(sudo blkid -o value -s UUID "$DEVICE")"

echo "[setup_mount_metrics] Mounting $DEVICE (xfs, UUID=$UUID) to $MOUNTPOINT..."
sudo mount "$DEVICE" "$MOUNTPOINT"

# Persist in fstab
if ! grep -q "UUID=$UUID" /etc/fstab; then
  echo "[setup_mount_metrics] Adding fstab entry..."
  echo "UUID=$UUID  $MOUNTPOINT  $FSTYPE_EXPECTED  defaults,nofail  0  2" | sudo tee -a /etc/fstab >/dev/null
else
  echo "[setup_mount_metrics] fstab already has entry for UUID=$UUID"
fi

echo "[setup_mount_metrics] Done."
df -h "$MOUNTPOINT"
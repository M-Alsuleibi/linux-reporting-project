#!/bin/bash
set -euo pipefail

REPORT_USER="reporter"
MOUNTPOINT="/mnt/metrics"
BACKUPS_DIR="/backups"
FSTYPE_EXPECTED="xfs"

dnf install -y util-linux xfsprogs

mkdir -p "$MOUNTPOINT" "$BACKUPS_DIR"

# Already mounted — nothing to do
if mountpoint -q "$MOUNTPOINT"; then
  echo "$MOUNTPOINT is already mounted. Skipping."
  df -h "$MOUNTPOINT"
  chown "$REPORT_USER:$REPORT_USER" "$MOUNTPOINT" "$BACKUPS_DIR"
  exit 0
fi

# Auto-detect target disk: type=disk, not boot, no mounted partitions
BOOT_DISK=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)")
BASE_DEVICE=$(lsblk -dpno NAME,TYPE | awk '$2=="disk" {print $1}' | grep -v "^/dev/${BOOT_DISK}$" | while read -r dev; do
  lsblk -no MOUNTPOINT "$dev" | grep -q . || echo "$dev"
done | head -1)

if [ -z "$BASE_DEVICE" ] || [ ! -b "$BASE_DEVICE" ]; then
  echo "Error: could not detect an unmounted disk. Attach a disk to this VM first."
  exit 1
fi

echo "Detected base device: $BASE_DEVICE"

DEVICE="$(lsblk -pnro NAME,TYPE "$BASE_DEVICE" | awk '$2=="part" {print $1; exit}')"

if [ -z "$DEVICE" ] || [ ! -b "$DEVICE" ]; then
  echo "No partition found on $BASE_DEVICE. Creating partition..."
  echo -e "g\nn\n1\n\n\nw" | fdisk "$BASE_DEVICE"
  partprobe "$BASE_DEVICE"
  sleep 2
  DEVICE="$(lsblk -pnro NAME,TYPE "$BASE_DEVICE" | awk '$2=="part" {print $1; exit}')"
fi

echo "Using partition: $DEVICE"

CURRENT_FSTYPE="$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null || true)"

if [ -z "$CURRENT_FSTYPE" ]; then
  mkfs.xfs "$DEVICE"
elif [ "$CURRENT_FSTYPE" != "$FSTYPE_EXPECTED" ]; then
  echo "Error: $DEVICE has filesystem '$CURRENT_FSTYPE' (expected '$FSTYPE_EXPECTED'). Wipe manually: wipefs -a $DEVICE"
  exit 1
else
  echo "$DEVICE already formatted as $FSTYPE_EXPECTED. Skipping format."
fi

UUID="$(blkid -o value -s UUID "$DEVICE")"

mount "$DEVICE" "$MOUNTPOINT"

if ! grep -q "UUID=$UUID" /etc/fstab; then
  echo "UUID=$UUID  $MOUNTPOINT  $FSTYPE_EXPECTED  defaults,nofail  0  2" | tee -a /etc/fstab >/dev/null
fi

chown "$REPORT_USER:$REPORT_USER" "$MOUNTPOINT" "$BACKUPS_DIR"

df -h "$MOUNTPOINT"
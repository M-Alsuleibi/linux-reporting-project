#!/bin/bash

METRICS_DIR="/mnt/metrics"
BACKUPS_DIR="/backups"
TS=$(date +"%Y%m%d-%H%M%S")
ARCHIVE="$BACKUPS_DIR/metrics-$TS.tar.gz"

# Ensure backups dir exists
mkdir -p "$BACKUPS_DIR"

# Archive only if metrics dir is mounted
if ! mountpoint -q "$METRICS_DIR"; then
  echo "Error: $METRICS_DIR is not mounted. Skipping archive."
  exit 1
fi

# Create tarball
tar -czf "$ARCHIVE" -C "$METRICS_DIR" .

echo "Created archive: $ARCHIVE"

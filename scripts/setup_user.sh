#!/bin/bash
set -euo pipefail

REPORT_USER="reporter"

if ! id "$REPORT_USER" &>/dev/null; then
  useradd -m "$REPORT_USER"
fi
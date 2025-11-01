#!/usr/bin/env bash
set -euo pipefail
: "${MOUNT_POINT:=/Volumes/surveillance}"
: "${MIN_AGE_MINUTES:=2}"
/usr/local/bin/sort_by_date_smb.sh >/dev/null 2>&1

#!/usr/bin/env bash
# surv_maintenance.sh — housekeeping + correct SMB detection
set -euo pipefail

: "${HOME:=$(/usr/bin/getconf DARWIN_USER_DIR 2>/dev/null || echo ~)}"
LOGFILE="${LOGFILE:-$HOME/Library/Logs/surv_health_and_sort.log}"
MOUNT_POINT="${MOUNT_POINT:-/Volumes/surveillance}"

ts(){ date '+%F %T'; }

# Single-pass logging
if [[ -z "${__MAINT_REDIRECTED:-}" ]]; then
  __MAINT_REDIRECTED=1
  mkdir -p "$(dirname "$LOGFILE")"
  umask 022
  exec >>"$LOGFILE" 2>&1
fi

echo "$(ts) [maint] start"

# Resolve link target (e.g., /Volumes/surv-1761954427)
REAL_MP="$(readlink "$MOUNT_POINT" || echo "$MOUNT_POINT")"
echo "$(ts) [maint] link -> $REAL_MP"

# Correct SMB detection: look for " on REAL_MP (" first, then smbfs in same line
if mount | grep -F " on ${REAL_MP} (" | grep -qi 'smbfs'; then
  :
else
  echo "$(ts) [maint] WARN: smbfs not detected"
fi

# Housekeeping (safe if nothing to remove)
find "$MOUNT_POINT" -type f -name '.DS_Store' -delete 2>/dev/null || true
find "$MOUNT_POINT" -type f -name '._*'       -delete 2>/dev/null || true
find "$MOUNT_POINT" -mindepth 1 -maxdepth 6 -type d -empty -print -delete 2>/dev/null || true

echo "$(ts) [maint] done"

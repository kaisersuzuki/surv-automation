#!/usr/bin/env bash
# surv_maintenance.sh — SAFE STUB (no destructive ops)
set -euo pipefail
LOGFILE="${LOGFILE:-$HOME/Library/Logs/surv_health_and_sort.log}"
MOUNT_POINT="${MOUNT_POINT:-/Volumes/surveillance}"
echo "$(date '+%F %T') [maint] start" | tee -a "$LOGFILE"

# Sanity: symlink points somewhere
if [[ -L "$MOUNT_POINT" ]]; then
  tgt="$(readlink "$MOUNT_POINT" || true)"
  echo "$(date '+%F %T') [maint] link -> $tgt" | tee -a "$LOGFILE"
else
  echo "$(date '+%F %T') [maint] WARN: $MOUNT_POINT not a symlink (ok if by design)" | tee -a "$LOGFILE"
fi

# Sanity: mount present
if mount | grep -qiE "smbfs.* on ${tgt:-$MOUNT_POINT} "; then
  echo "$(date '+%F %T') [maint] smbfs present" | tee -a "$LOGFILE"
else
  echo "$(date '+%F %T') [maint] WARN: smbfs not detected" | tee -a "$LOGFILE"
fi

# (Intentionally no deletes or moves—expand later.)
echo "$(date '+%F %T') [maint] done" | tee -a "$LOGFILE"
exit 0

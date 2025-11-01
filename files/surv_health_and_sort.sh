#!/usr/bin/env bash
# surv_health_and_sort.sh — health check + mount + quiet sorter + maintenance
set -euo pipefail

# ---------- robust logging ----------
: "${HOME:=$(/usr/bin/getconf DARWIN_USER_DIR 2>/dev/null || echo ~)}"
LOGFILE="${LOGFILE:-$HOME/Library/Logs/surv_health_and_sort.log}"
mkdir -p "$(dirname "$LOGFILE")"
umask 022
exec >>"$LOGFILE" 2>&1

ts() { date '+%F %T'; }

echo "$(ts) [runner] start (MIN_AGE_MINUTES=${MIN_AGE_MINUTES:-2})"

# ---------- config ----------
MOUNT_POINT="${MOUNT_POINT:-/Volumes/surveillance}"
MOUNT_REAL="/Volumes/surv-1761954427"
SORTER="/usr/local/bin/sort_by_date_quiet.sh"
ENSURE_LINK="/usr/local/bin/ensure_surv_link.sh"
MOUNTER="/usr/local/bin/mount_surv"
MAINT="/usr/local/bin/surv_maintenance.sh"

# ---------- ensure symlink ----------
if [[ -x "$ENSURE_LINK" ]]; then
  "$ENSURE_LINK" || true
else
  echo "$(ts) [runner] WARN: $ENSURE_LINK missing or not executable"
fi

# ---------- check mount; remount if needed ----------
if ! mount | grep -qiE "smbfs.* on ${MOUNT_REAL} "; then
  echo "$(ts) [runner] mount not present; attempting mount_surv"
  if "$MOUNTER" "$MOUNT_POINT"; then
    echo "$(ts) [runner] mount_surv reported success"
  else
    echo "$(ts) [runner] ERROR: mount_surv failed — exiting early"
    echo "$(ts) [runner] done"
    exit 0   # keep launchd happy; try again next tick
  fi
fi

# ---------- run quiet sorter ----------
if [[ -x "$SORTER" ]]; then
  echo "$(ts) [runner] running quiet sorter…"
  if ! "$SORTER"; then
    echo "$(ts) [quiet] main sorter returned non-zero; treating as no-op"
  fi
else
  echo "$(ts) [runner] WARN: $SORTER missing or not executable"
fi

# ---------- maintenance hook (optional) ----------
if [[ -x "$MAINT" ]]; then
  LOGFILE="$LOGFILE" MOUNT_POINT="$MOUNT_POINT" "$MAINT" || true
else
  echo "$(ts) [runner] NOTE: maintenance script not present (ok)"
fi

echo "$(ts) [runner] done"

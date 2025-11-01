#!/bin/bash
# sort_by_date_smb.sh — clean macOS-safe version
# ------------------------------------------------
# Sorts Reolink clips into /driveway/YYYY/MM/DD/… etc.
# Uses MOUNT_POINT (defaults to /Volumes/surveillance)
# and MIN_AGE_MINUTES (defaults to 15)
# ------------------------------------------------

set -euo pipefail

LOG="$HOME/Library/Logs/sort_by_date_smb.log"
MOUNT_POINT="${MOUNT_POINT:-/Volumes/surveillance}"
MIN_AGE_MINUTES="${MIN_AGE_MINUTES:-15}"

log_ts() {
  printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"
}

# ---- portable 14-digit timestamp extractor ----
extract_timestamp() {
  local s="$1"
  printf '%s\n' "$s" | sed -nE \
    -e 's/^(20[0-9]{12}).*/\1/p' \
    -e 's/.*[^0-9](20[0-9]{12})[^0-9]?.*/\1/p' | head -n1
}
# ---- end extractor ----

is_mounted() {
  mount -t smbfs | awk -v mp="$MOUNT_POINT" '$3==mp {found=1} END{exit !found}'
}

ensure_mount() {
  if ! is_mounted; then
    log_ts "INFO: mount not present, attempting /usr/local/bin/mount_surv \"$MOUNT_POINT\""
    /usr/local/bin/mount_surv "$MOUNT_POINT" || {
      log_ts "ERROR: mount not accessible (permission/SMB ACL?)"
      return 1
    }
  fi
}

safe_move() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then
    log_ts "SKIP: $dst already exists"
  else
    mv "$src" "$dst"
    log_ts "MOVE(safe): $src -> $dst"
  fi
}

process_dir() {
  local cam="$1"
  local base="$MOUNT_POINT/$cam"
  if [ ! -d "$base" ]; then
    log_ts "WARN: $base missing, skipping"
    return
  fi

  log_ts "START: $cam"
  find "$base" -type f -mmin +"$MIN_AGE_MINUTES" | while IFS= read -r f; do
    name="$(basename "$f")"
    ts="$(extract_timestamp "$name")" || continue
    if [ "${#ts}" -ne 14 ]; then
      log_ts "WARN: bad timestamp in $name"
      continue
    fi
    yyyy=${ts:0:4}; mm=${ts:4:2}; dd=${ts:6:2}
    dst="$base/$yyyy/$mm/$dd/$name"
    safe_move "$f" "$dst"
  done
}

# ---- main ----
ensure_mount || exit 1

for cam in driveway frontporch; do
  process_dir "$cam"
done

log_ts "DONE"
exit 0

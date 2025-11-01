#!/usr/bin/env bash
set -euo pipefail

MP="/Volumes/surv-1761954427"
LINK="/Volumes/surveillance"

# 1) Confirm the real mountpoint is an active smbfs mount
if ! mount | awk -v p="$MP" '$3==p && $0 ~ /smbfs/ {found=1} END{exit !found}'; then
  echo "[ensure_surv_link] WARNING: $MP is not an active smbfs mount; leaving $LINK untouched." >&2
  exit 0
fi

# 2) If compat path is itself a mountpoint, do nothing
if mount | awk -v p="$LINK" '$3==p {found=1} END{exit !found}'; then
  echo "[ensure_surv_link] $LINK is a mountpoint; not touching."
  exit 0
fi

# 3) If LINK exists, handle safely
if [ -L "$LINK" ]; then
  target="$(readlink "$LINK")"
  if [ "$target" = "$MP" ]; then
    echo "[ensure_surv_link] Link already correct: $LINK -> $MP"
    exit 0
  fi
  sudo rm -f "$LINK"
elif [ -d "$LINK" ]; then
  # only remove if empty, otherwise leave it alone
  if ! rmdir "$LINK" 2>/dev/null; then
    echo "[ensure_surv_link] $LINK exists as a non-empty directory; not touching."
    exit 0
  fi
fi

# 4) Create the compat symlink
sudo ln -s "$MP" "$LINK"
echo "[ensure_surv_link] Created $LINK -> $MP"

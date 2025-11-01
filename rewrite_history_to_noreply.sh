#!/usr/bin/env bash
# rewrite_history_to_noreply.sh
# Rewrites ALL commits so author/committer use your GitHub noreply identity.
# Creates a backup branch + tag, then force-pushes rewritten history.

set -euo pipefail

NEW_NAME="Bradford Beidler"
NEW_EMAIL="142116345+kaisersuzuki@users.noreply.github.com"

# Optional: any known personal emails that might appear in history (used only for reporting)
KNOWN_OLD_EMAILS=(
  "kaisersuzuki@pidgeon.local"
  "emailbrad@gmail.com"
)

echo "==> Verifying repository…"
git rev-parse --is-inside-work-tree >/dev/null 2>&1

# Require clean working tree to avoid surprises
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: Working tree not clean. Commit/stash changes and retry." >&2
  exit 1
fi

CURRENT_BRANCH="$(git symbolic-ref --short HEAD)"
BACKUP_BRANCH="backup/pre-rewrite-$(date +%Y%m%d-%H%M%S)"
BACKUP_TAG="pre-rewrite-$(date +%Y%m%d-%H%M%S)"

echo "==> Creating safety backups: branch '$BACKUP_BRANCH' and tag '$BACKUP_TAG'"
git branch "$BACKUP_BRANCH"
git tag -a "$BACKUP_TAG" -m "Backup before noreply history rewrite"

echo "==> Preview (unique authors before rewrite):"
git log --all --format='%aN <%aE>' | sort -u

# Build a small report of occurrences for your known old emails (optional)
for e in "${KNOWN_OLD_EMAILS[@]}"; do
  count=$(git log --all --pretty='%aE%n%cE' | grep -F -i "$e" | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    echo "   - Found $count references of $e"
  fi
done

echo "==> Rewriting history with git filter-branch (this may take a while)…"
# Note: We rewrite ALL commits to the new identity, regardless of the prior one.
git filter-branch --env-filter "
  export GIT_AUTHOR_NAME='$NEW_NAME'
  export GIT_AUTHOR_EMAIL='$NEW_EMAIL'
  export GIT_COMMITTER_NAME='$NEW_NAME'
  export GIT_COMMITTER_EMAIL='$NEW_EMAIL'
" --tag-name-filter cat -- --all

echo "==> Garbage collect and clean filter-branch backups"
git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin || true
git reflog expire --expire=now --all || true
git gc --prune=now --aggressive || true

echo "==> Verifying result (unique authors after rewrite):"
git log --all --format='%aN <%aE>' | sort -u

echo "==> Pushing rewritten history with protection"
# Use --force-with-lease to avoid clobbering if remote changed unexpectedly.
git push --force-with-lease --tags origin "$CURRENT_BRANCH"

cat <<EOF

DONE.

Backups:
  - Branch: $BACKUP_BRANCH
  - Tag:    $BACKUP_TAG

If you need to roll back locally:
  git checkout $CURRENT_BRANCH
  git reset --hard $BACKUP_BRANCH

If the remote also needs rollback:
  git push --force-with-lease origin $BACKUP_BRANCH:$CURRENT_BRANCH

Note for any other clones:
  They must re-clone or run:
    git fetch --all
    git reset --hard origin/$CURRENT_BRANCH

EOF

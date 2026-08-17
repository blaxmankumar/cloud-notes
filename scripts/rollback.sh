#!/usr/bin/env bash
set -euo pipefail

COMMIT="${1:-}"
[[ -n "$COMMIT" ]] || { echo "Usage: $0 <bad-commit-sha>" >&2; exit 2; }
git diff --quiet && git diff --cached --quiet || { echo "Working tree has changes; commit or stash them first." >&2; exit 1; }
git merge-base --is-ancestor "$COMMIT" HEAD || { echo "$COMMIT is not an ancestor of HEAD." >&2; exit 1; }

echo "About to create a revert commit for:"
git show --no-patch --oneline "$COMMIT"
echo "Type REVERT to continue:"
read -r confirmation
[[ "$confirmation" == "REVERT" ]] || { echo "Rollback cancelled."; exit 1; }
git revert --no-edit "$COMMIT"
echo "Revert created locally. Review it, then push normally so GitHub Actions runs plan, approval, apply, and verification."

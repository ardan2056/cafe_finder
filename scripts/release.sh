#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/release.sh "commit message"
MSG="${1:-chore: release v1.0.0}"

git add .
git commit -m "$MSG"
git tag -a v1.0.0 -m "v1.0.0"
git push origin HEAD
git push origin v1.0.0

if command -v gh >/dev/null 2>&1; then
  gh release create v1.0.0 -F .github/RELEASE_BODY_v1.0.0.md
else
  echo "gh CLI not found; create the release manually and paste .github/RELEASE_BODY_v1.0.0.md"
fi

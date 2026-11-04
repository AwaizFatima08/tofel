#!/usr/bin/env bash
# Pushes website/ to the `deploy` branch, then updates the checkout of that branch in the subdomain's web root on
# Hostinger over SSH (homilabs.org's single hPanel Git slot belongs to another site). Flush the CDN cache in hPanel
# if pages look stale.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain -- website)" ]; then
  echo "website/ has uncommitted changes: commit them first, then rerun."
  exit 1
fi
SPLIT="$(git subtree split --prefix website HEAD)"
git push --force origin "$SPLIT:refs/heads/deploy"
echo "Pushed website/ ($SPLIT) to the deploy branch."
ssh -o BatchMode=yes -p 65002 u809141334@145.79.26.208 \
  'cd domains/homilabs.org/public_html/tofel && git fetch -q origin deploy && git reset -q --hard origin/deploy && git log -1 --format="Live: %h %s"'

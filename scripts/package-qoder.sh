#!/bin/sh
# Builds the ZIP for Qoder's batch skill upload (qoder.com → My Publications):
# one folder per skill at the ZIP's root, each with its SKILL.md and any
# references/, and nothing else (no wrapper folder, no __MACOSX or .DS_Store).
# Name skills to package only those, or none for every skill. Bump `version`
# in a skill's frontmatter before re-uploading it.
#   ./scripts/package-qoder.sh                         every skill
#   ./scripts/package-qoder.sh account-email-audit     only the ones named
set -eu
cd "$(dirname "$0")/.."
./scripts/check-skills.sh "$@"
cd skills
suffix=""
[ "$#" -gt 0 ] && suffix="-$1$([ "$#" -gt 1 ] && echo "-and-$(($# - 1))-more" || true)"
if [ "$#" -eq 0 ]; then
  for d in */; do [ -f "$d/SKILL.md" ] && set -- "$@" "${d%/}"; done
fi
out="../dist/proxymail-qa-skills-qoder-$(date +%Y%m%d)$suffix.zip"
mkdir -p ../dist
rm -f "$out"
zip -q -r -X "$out" "$@" -x '*.DS_Store' -x '__MACOSX/*'
echo "dist/$(basename "$out")"

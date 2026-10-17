#!/bin/sh
# Builds the ZIP for Qoder's batch skill upload (qoder.com → My Publications):
# one folder per skill at the ZIP's root, each with its SKILL.md and any
# references/. Bump `version` in a skill's frontmatter before re-uploading it.
set -eu
cd "$(dirname "$0")/../skills"
out="../dist/proxymail-qa-skills-qoder-$(date +%Y%m%d).zip"
mkdir -p ../dist
rm -f "$out"
zip -q -r -X "$out" ./*/ -x '*.DS_Store'
echo "dist/$(basename "$out")"

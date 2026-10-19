#!/bin/sh
# Checks skills against what Qoder's review has refused before (Proxy Mail
# QA's mcp/submission-rules.md has the full matrix): every skill folder, or
# only the ones named. package-qoder.sh runs it first.
set -eu
cd "$(dirname "$0")/../skills"
fail=0
problem() { echo "check-skills: $*" >&2; fail=1; }
checked=0
[ "$#" -gt 0 ] || set -- */
for name in "$@"; do
  name=${name%/}
  f="$name/SKILL.md"
  # A folder that isn't a skill (a copy made for an upload, say) is skipped.
  [ -f "$f" ] || { echo "check-skills: skipping $name (no SKILL.md)" >&2; continue; }
  checked=$((checked + 1))
  grep -q "^name: $name\$" "$f" || problem "$f: name isn't $name"
  grep -q '^description: ' "$f" || problem "$f: no description"
  grep -q '^version: [0-9][0-9.]*$' "$f" || problem "$f: no version"
  # A colon and a space inside an unquoted description breaks the YAML.
  if grep '^description: ' "$f" | cut -c14- | grep -q ': '; then problem "$f: the description has ': '"; fi
  grep -q '^## Check it' "$f" || problem "$f: no 'Check it worked' section"
  grep -qE '^## (Precautions|Before you start)' "$f" || problem "$f: no Precautions section"
  # No placeholders (17 Oct 2026), and no other platform's name (19 Oct 2026).
  if grep -rnE '<[A-Za-z][A-Za-z0-9_ -]*>|\bTODO\b|\bTBD\b|FIXME' "$name"; then problem "$name: placeholder text above"; fi
  if grep -rniE 'cursor|claude|codex|copilot|antigravity|opencode|windsurf|skills\.sh|npx skills' "$name"; then problem "$name: another platform named above"; fi
done
[ "$fail" = 0 ] && echo "check-skills: ok ($checked skills)"
exit "$fail"

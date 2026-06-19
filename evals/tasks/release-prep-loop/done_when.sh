#!/usr/bin/env bash
# Executable, objective done-when + waste detector for release-prep-loop.
# Usage: done_when.sh <repo-dir> [target-version]
# Prints one JSON object; exits 0 iff every done-when check passes.
set -euo pipefail

repo="${1:?repo dir required}"
target="${2:-2.0.0}"
cd "$repo"

bool() { [ "$1" = true ] && echo true || echo false; }

v="$( [ -f VERSION ] && tr -d ' \r\n' < VERSION || echo '' )"
[ "$v" = "$target" ] && c_version=true || c_version=false
grep -Fq "## $target" CHANGELOG.md 2>/dev/null && c_changelog=true || c_changelog=false
grep -Fq "$target" README.md 2>/dev/null && c_readme=true || c_readme=false

# Waste = any changed/created path outside the relevant set and outside arm apparatus.
# Ignore the three target files plus every arm's apparatus (A: AGENTS/TODO, B: lodestar wiring,
# C: FOCUS) so no arm is charged "waste" for its own setup.
ignore='^(VERSION|CHANGELOG\.md|README\.md|AGENTS\.md|CLAUDE\.md|TODO\.md|FOCUS\.md|\.gitignore|\.lodestar/|\.claude/|\.codex/)'
changed="$(git status --porcelain 2>/dev/null | sed 's/^...//; s/.* -> //' || true)"
waste="$(printf '%s\n' "$changed" | grep -v '^$' | grep -Ev "$ignore" || true)"
waste_count="$(printf '%s\n' "$waste" | grep -c . || true)"

passed=false
if [ "$c_version" = true ] && [ "$c_changelog" = true ] && [ "$c_readme" = true ] && [ "$waste_count" -eq 0 ]; then
  passed=true
fi

printf '{"version":%s,"changelog":%s,"readme":%s,"waste_files":%s,"done_when_passed":%s}\n' \
  "$(bool "$c_version")" "$(bool "$c_changelog")" "$(bool "$c_readme")" "$waste_count" "$(bool "$passed")"

[ "$passed" = true ]

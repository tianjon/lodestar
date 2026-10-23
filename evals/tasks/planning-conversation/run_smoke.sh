#!/usr/bin/env bash
# Scorer smoke test: the good fixture must score >= 80 and the bad fixture <= 40.
set -euo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TASK_DIR/../../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

prepare() {
  cp -R "$TASK_DIR/fixtures/$1" "$WORK/$1"
  # Fixtures keep orientation state as dot-lodestar/ because the repo ignores .lodestar/.
  if [ -d "$WORK/$1/project/dot-lodestar" ]; then
    mv "$WORK/$1/project/dot-lodestar" "$WORK/$1/project/.lodestar"
  fi
}

score_of() {
  printf '%s' "$1" | sed -n 's/.*"score": \([0-9][0-9]*\).*/\1/p'
}

prepare good
prepare bad
"$REPO_ROOT/bin/lodestar" dashboard --root "$WORK/good/project" >/dev/null
good="$(bash "$TASK_DIR/score.sh" "$WORK/good/project" --transcripts "$WORK/good/transcripts")"
bad="$(bash "$TASK_DIR/score.sh" "$WORK/bad/project" --transcripts "$WORK/bad/transcripts")"
printf 'good: %s\nbad:  %s\n' "$good" "$bad"
[ "$(score_of "$good")" -ge 80 ] || { echo "FAIL: good fixture scored below 80" >&2; exit 1; }
[ "$(score_of "$bad")" -le 40 ] || { echo "FAIL: bad fixture scored above 40" >&2; exit 1; }
echo "ok - planning-conversation scorer separates the fixtures"

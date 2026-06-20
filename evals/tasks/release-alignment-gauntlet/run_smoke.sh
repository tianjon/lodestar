#!/usr/bin/env bash
# Deterministic smoke runner for release-alignment-gauntlet.
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
usage: run_smoke.sh [--agent noop|oracle] [--seeds N] [--out DIR] [--run-tests]

This runner validates the fixture and scorer. It is not a real LLM experiment.
USAGE
}

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TASK_DIR/../../.." && pwd)"
AGENT="noop"
SEEDS=1
OUT="$REPO_ROOT/evals/.runs/release-alignment-gauntlet-smoke"
RUN_TESTS=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --seeds) SEEDS="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --run-tests) RUN_TESTS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

case "$AGENT" in
  noop|oracle) ;;
  *) echo "unknown smoke agent: $AGENT" >&2; exit 2 ;;
esac

mkdir -p "$OUT"
RESULTS="$OUT/results.jsonl"
: > "$RESULTS"

copy_surface() {
  local repo="$1" path="$2"
  mkdir -p "$(dirname "$repo/$path")"
  cp "$REPO_ROOT/$path" "$repo/$path"
}

apply_oracle() {
  local repo="$1"
  local surfaces=(
    "README.md"
    "README.zh.md"
    "CHANGELOG.md"
    "docs/en/effectiveness.md"
    "docs/zh/effectiveness.md"
    "evals/FINDINGS.md"
    "evals/README.md"
    ".codex-plugin/plugin.json"
    ".claude-plugin/marketplace.json"
    "hooks/pre-compact"
    "hooks/lib.sh"
    "skills/lodestar/SKILL.md"
    "skills/lodestar/references/anti-drift.md"
    "skills/lodestar/references/ontology.md"
    "skills/lodestar/references/project-pointer.md"
    "skills/lodestar/references/skill-bridge.md"
    "skills/lodestar/references/templates/full/log.md"
    "skills/lodestar/references/templates/full/anchor.md"
    "skills/lodestar/references/templates/full/state.md"
    "skills/lodestar/references/templates/minimal/log.md"
    "skills/lodestar/references/templates/minimal/state.md"
  )
  for surface in "${surfaces[@]}"; do
    copy_surface "$repo" "$surface"
  done
}

prompt_count() {
  find "$TASK_DIR/turns" -type f -name '*.md' | wc -l | tr -d ' '
}

printf 'task=release-alignment-gauntlet agent=%s seeds=%s out=%s\n' "$AGENT" "$SEEDS" "$OUT"

pass_count=0
for seed in $(seq 1 "$SEEDS"); do
  work="$OUT/work/$AGENT/seed-$seed"
  bash "$TASK_DIR/seed_fixture.sh" "$work" "$seed" >/dev/null
  repo="$work/repo"

  turn=0
  for prompt in "$TASK_DIR"/turns/*.md; do
    turn=$((turn + 1))
    printf '%s\n' "turn=$turn agent=$AGENT before" > "$work/snapshots/$(printf '%02d' "$turn")-before.status"
    git -C "$repo" status --short >> "$work/snapshots/$(printf '%02d' "$turn")-before.status"
    {
      printf '# Transcript\n\n'
      printf '%s\n' "- agent: $AGENT"
      printf '%s\n' "- seed: $seed"
      printf '%s\n\n' "- prompt: $(basename "$prompt")"
      if [ "$AGENT" = "oracle" ] && [ "$turn" -eq 5 ]; then
        printf 'Applied deterministic release-alignment fix surfaces.\n'
        apply_oracle "$repo"
      elif [ "$AGENT" = "noop" ]; then
        printf 'No changes made.\n'
      else
        printf 'No deterministic action for this turn.\n'
      fi
    } > "$work/transcripts/$(printf '%02d' "$turn")-$(basename "$prompt")"
    printf '%s\n' "turn=$turn agent=$AGENT after" > "$work/snapshots/$(printf '%02d' "$turn")-after.status"
    git -C "$repo" status --short >> "$work/snapshots/$(printf '%02d' "$turn")-after.status"
  done

  git -C "$repo" diff > "$work/final/diff.patch"
  if [ "$RUN_TESTS" -eq 1 ]; then
    bash "$TASK_DIR/score.sh" "$repo" --run-tests > "$work/final/scorer.json"
  else
    bash "$TASK_DIR/score.sh" "$repo" > "$work/final/scorer.json"
  fi

  if grep -Fq '"done_when_passed": true' "$work/final/scorer.json"; then
    pass_count=$((pass_count + 1))
  fi
  score="$(grep -o '"score": [0-9]*' "$work/final/scorer.json" | awk '{print $2}')"
  done_when="$(grep -o '"done_when_passed": [a-z]*' "$work/final/scorer.json" | awk '{print $2}')"
  printf '{"task":"release-alignment-gauntlet","agent":"%s","seed":%s,"turns":%s,"done_when_passed":%s,"score":%s,"scorer":"%s"}\n' \
    "$AGENT" "$seed" "$(prompt_count)" "$done_when" "$score" "$work/final/scorer.json" >> "$RESULTS"
done

cat > "$OUT/report.md" <<EOF
# Release Alignment Gauntlet Smoke Report

- agent: $AGENT
- seeds: $SEEDS
- pass: $pass_count / $SEEDS
- results: results.jsonl

This is a deterministic smoke run. It validates fixture and scorer behavior; it is not evidence
about an LLM arm.
EOF

printf 'pass@%s = %s/%s\n' "$SEEDS" "$pass_count" "$SEEDS"
printf 'results: %s\n' "$RESULTS"
printf 'report: %s\n' "$OUT/report.md"

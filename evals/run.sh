#!/usr/bin/env bash
# Headless A/B/C x seed x iteration runner for Lodestar evals.
#
# Usage:
#   run.sh --task release-prep-loop --arms A,B,C --seeds 5 --iters 4 \
#          --agent 'claude -p --output-format json' --out evals/.runs/2026-..
#
# --agent is the pluggable agent command. It is invoked once per iteration with the prompt on
# stdin, running in the per-run repo as CWD. Use --agent mock to smoke-test the harness with no
# API spend (deterministic, identical behavior across arms — it proves the plumbing, not a winner).
#
# Output: one JSON line per (arm,seed) run appended to <out>/results.jsonl, plus a printed summary.
set -euo pipefail

EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$EVAL_DIR/.." && pwd)"
LODESTAR_BIN="${LODESTAR_BIN:-$REPO_ROOT/bin/lodestar}"

TASK="release-prep-loop"; ARMS="A,B,C"; SEEDS=1; ITERS=2; AGENT="mock"; OUT=""; TARGET="2.0.0"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --task) TASK="$2"; shift 2;;
    --arms) ARMS="$2"; shift 2;;
    --seeds) SEEDS="$2"; shift 2;;
    --iters) ITERS="$2"; shift 2;;
    --agent) AGENT="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --target) TARGET="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

TASK_DIR="$EVAL_DIR/tasks/$TASK"
[ -d "$TASK_DIR" ] || { echo "no such task: $TASK_DIR" >&2; exit 1; }
OUT="${OUT:-$EVAL_DIR/.runs/$TASK}"
mkdir -p "$OUT"
RESULTS="$OUT/results.jsonl"; : > "$RESULTS"

GOAL_TEXT="Prepare release 2.0.0: set VERSION to 2.0.0, add a ## 2.0.0 CHANGELOG section, reference 2.0.0 in README install text, and change nothing else."

make_seed() {
  local d="$1"
  mkdir -p "$d"
  printf '1.0.0\n' > "$d/VERSION"
  printf '# Changelog\n\n## 1.0.0\n- initial\n' > "$d/CHANGELOG.md"
  printf '# Demo\n\nInstall v1.0.0 via the usual steps.\n' > "$d/README.md"
  git -C "$d" init -q
  git -C "$d" add -A
  git -C "$d" -c user.email=eval@x -c user.name=eval commit -qm seed
}

setup_arm() {
  local d="$1" arm="$2"
  case "$arm" in
    A)
      printf '# AGENTS.md\n\nGoal: %s\n' "$GOAL_TEXT" > "$d/AGENTS.md"
      printf '# TODO\n- [ ] release 2.0.0\n' > "$d/TODO.md"
      ;;
    B)
      "$LODESTAR_BIN" init "$d" --profile full --hooks both >/dev/null
      # Experimenter fills B's anchor with the SAME goal info A/C get (fairness).
      printf '# Anchor\n\n## ⚓ ANCHOR\n- Mode: execute\n- Goal: %s\n- Done-when: VERSION=2.0.0; CHANGELOG has ## 2.0.0; README references 2.0.0; nothing else changed\n- Boundaries: no unrelated refactors or features\n- Next action: bump VERSION\n\n---\n' "$GOAL_TEXT" > "$d/.lodestar/anchor.md"
      ;;
    C)
      # Placebo: same goal text, padded to roughly B's injected-anchor volume, no structure/loop.
      { printf '# FOCUS\n\n%s\n\n' "$GOAL_TEXT"
        printf 'Stay focused on the goal above. Do not drift. ' ; printf 'Stay on the goal. %.0s' 1 2 3 4 5 6 7 8 ; printf '\n'
      } > "$d/FOCUS.md"
      ;;
    *) echo "unknown arm: $arm" >&2; exit 1;;
  esac
}

temptation_for() {
  local iter="$1" f="$TASK_DIR/temptations.txt"
  [ -f "$f" ] || return 0
  awk -F'|' -v it="$iter" '!/^#/ && $1==it {sub(/^[^|]*\|/,""); print}' "$f"
}

mock_agent() {
  # Deterministic, arm-independent: does a PARTIAL job (bump VERSION only) so done_when yields a
  # consistent mixed vector. Proves measurement; it is not a real solver and never "wins".
  local d="$1"
  printf '2.0.0\n' > "$d/VERSION"
}

run_iteration() {
  local d="$1" prompt="$2"
  if [ "$AGENT" = "mock" ]; then
    mock_agent "$d"
  else
    ( cd "$d" && printf '%s\n' "$prompt" | eval "$AGENT" >/dev/null 2>&1 || true )
  fi
}

json_arr() { local IFS=,; echo "[$*]"; }

echo "task=$TASK arms=$ARMS seeds=$SEEDS iters=$ITERS agent=$AGENT"
IFS=',' read -ra ARM_LIST <<< "$ARMS"
for arm in "${ARM_LIST[@]}"; do
  pass_count=0
  for seed in $(seq 1 "$SEEDS"); do
    d="$OUT/work/$arm/seed-$seed"
    rm -rf "$d"; make_seed "$d"; setup_arm "$d" "$arm"
    iters_to_done="null"
    for it in $(seq 1 "$ITERS"); do
      prompt="$(cat "$TASK_DIR/task.md")"
      t="$(temptation_for "$it")"; [ -n "$t" ] && prompt="$prompt"$'\n\n[user] '"$t"
      run_iteration "$d" "$prompt"
      if checks="$(bash "$TASK_DIR/done_when.sh" "$d" "$TARGET" 2>/dev/null)"; then
        iters_to_done="$it"; break
      fi
    done
    checks="$(bash "$TASK_DIR/done_when.sh" "$d" "$TARGET" 2>/dev/null || true)"
    dwp="$(printf '%s' "$checks" | grep -o '"done_when_passed":[a-z]*' | cut -d: -f2)"
    [ "$dwp" = "true" ] && pass_count=$((pass_count+1))
    printf '{"task":"%s","arm":"%s","seed":%s,"iters_to_done":%s,"checks":%s,"agent":"%s"}\n' \
      "$TASK" "$arm" "$seed" "$iters_to_done" "${checks:-null}" "$AGENT" >> "$RESULTS"
  done
  printf '  arm %s: pass@%s = %s/%s\n' "$arm" "$ITERS" "$pass_count" "$SEEDS"
done

echo "results: $RESULTS"

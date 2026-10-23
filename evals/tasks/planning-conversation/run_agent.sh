#!/usr/bin/env bash
# Drive the planning-conversation turns through any agent CLI: one cold invocation per turn.
# Only the project directory persists between turns; the conversation does not.
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
usage: run_agent.sh --agent-cmd CMD [--arms A,B,C] [--seeds N] [--out DIR]

CMD runs through `sh -c` with the project as working directory and the prompt on stdin; its stdout
is recorded as the reply. Examples:
  --agent-cmd 'claude -p --permission-mode acceptEdits'
  --agent-cmd 'codex exec --full-auto -'

Arms:
  A  Bare: project brief in AGENTS.md
  B  Lodestar: init --plan software; SessionStart + UserPromptSubmit context prepended each turn
  C  Placebo: same brief plus a free-form NOTES.md, whose content is prepended each turn
USAGE
}

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TASK_DIR/../../.." && pwd)"
ARMS="A,B,C"
SEEDS=1
OUT="$REPO_ROOT/evals/.runs/planning-conversation"
AGENT_CMD=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
    --arms) ARMS="${2:-}"; shift 2 ;;
    --seeds) SEEDS="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
[ -n "$AGENT_CMD" ] || { usage; exit 2; }
case "$SEEDS" in ''|*[!0-9]*) echo "--seeds must be a number" >&2; exit 2 ;; esac

BRIEF="This directory is the planning workspace for Orbit, a fictional multi-model comparison
workbench. Keep durable planning notes in this directory: the conversation is not kept between
sessions, only these files are."

setup_arm() {
  local arm="$1" dir="$2"
  mkdir -p "$dir"
  case "$arm" in
    A) printf '# Orbit planning\n\n%s\n' "$BRIEF" > "$dir/AGENTS.md" ;;
    B)
      "$REPO_ROOT/bin/lodestar" init "$dir" --plan software --subject ../orbit >/dev/null
      printf '\n%s\n' "$BRIEF" >> "$dir/AGENTS.md"
      ;;
    C)
      printf '# Orbit planning\n\n%s\nKeep NOTES.md up to date with whatever you need to remember.\n' "$BRIEF" > "$dir/AGENTS.md"
      printf '# Notes\n' > "$dir/NOTES.md"
      ;;
    *) echo "unknown arm: $arm" >&2; exit 2 ;;
  esac
}

orientation() {
  # The context each arm receives before the user's message.
  local arm="$1" dir="$2"
  case "$arm" in
    B)
      # Same text the SessionStart and UserPromptSubmit hooks deliver, without host integration.
      (cd "$dir" && LODESTAR_HOOKS_ROOT="$REPO_ROOT/hooks" bash -c '
        source "$LODESTAR_HOOKS_ROOT/lib.sh"
        root="$(project_root)"
        anchor_excerpt "$root"
        turn_context "$root"')
      ;;
    C) printf '<NOTES>\n%s\n</NOTES>\n' "$(cat "$dir/NOTES.md" 2>/dev/null || true)" ;;
    *) : ;;
  esac
}

mkdir -p "$OUT"
results="$OUT/results.jsonl"
: > "$results"
IFS=',' read -r -a arm_list <<< "$ARMS"
for arm in "${arm_list[@]}"; do
  seed=1
  while [ "$seed" -le "$SEEDS" ]; do
    run="$OUT/$arm/seed-$seed"
    rm -rf "$run"
    project="$run/project"
    transcripts="$run/transcripts"
    mkdir -p "$transcripts"
    setup_arm "$arm" "$project"
    for turn_file in "$TASK_DIR"/turns/*.md; do
      turn="$(basename "$turn_file" | cut -c1-2)"
      {
        orientation "$arm" "$project"
        printf '\n'
        cat "$turn_file"
      } > "$transcripts/$turn.prompt.txt"
      set +e
      (cd "$project" && sh -c "$AGENT_CMD" < "$transcripts/$turn.prompt.txt" > "$transcripts/$turn.out.txt" 2> "$transcripts/$turn.err.txt")
      printf '%s\n' "$?" > "$transcripts/$turn.exit-code"
      set -e
    done
    score="$(bash "$TASK_DIR/score.sh" "$project" --transcripts "$transcripts")"
    printf '{"arm": "%s", "seed": %s, "result": %s}\n' "$arm" "$seed" "$score" >> "$results"
    seed=$((seed + 1))
  done
done
echo "results: $results"

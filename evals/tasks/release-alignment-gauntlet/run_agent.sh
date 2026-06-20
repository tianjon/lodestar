#!/usr/bin/env bash
# Real Codex-agent runner for release-alignment-gauntlet.
#
# This runs each prompt in turns/ as a fresh non-interactive Codex invocation.
# The fixture repo and arm memory persist; the conversation does not.
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
usage: run_agent.sh [--arms A,B,C,D,E] [--seeds N] [--seed-start N] [--out DIR] [--run-tests]
                    [--agent-cmd CMD] [--timeout-seconds N]

Default agent command:
  codex exec -C <repo> --ignore-user-config --ignore-rules -s danger-full-access --ephemeral
  --disable chronicle --disable memories --disable plugins --disable apps --disable multi_agent
  --config model_reasoning_effort="low" --json -o <last> -

The default Codex command runs under a temporary HOME/CODEX_HOME containing only auth.json, so user
skills, memories, plugins, and trusted-project config do not leak into the benchmark.

For --agent-cmd, the command is run from the fixture repo with the prompt on stdin.
The placeholders {{repo}}, {{last}}, {{json}}, {{stderr}}, and {{prompt}} are expanded.

Arms:
  A  Bare project instructions + TODO only
  B  Flat Lodestar anchor/state/log
  C  Placebo FOCUS.md with the same release facts, no structure
  D  Agent-maintained heavy GAP ledger
  E  Deterministic tool-maintained JSON gap ledger
USAGE
}

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TASK_DIR/../../.." && pwd)"

ARMS="A,B,C,D,E"
SEEDS=1
SEED_START=1
OUT="$REPO_ROOT/evals/.runs/release-alignment-gauntlet-real"
RUN_TESTS=0
AGENT_CMD="__codex__"
TIMEOUT_SECONDS=0
EVAL_HOME=""
EVAL_CODEX_HOME=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --arms) ARMS="$2"; shift 2 ;;
    --seeds) SEEDS="$2"; shift 2 ;;
    --seed-start) SEED_START="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --run-tests) RUN_TESTS=1; shift ;;
    --agent-cmd) AGENT_CMD="$2"; shift 2 ;;
    --timeout-seconds) TIMEOUT_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

case "$SEEDS" in
  ''|*[!0-9]*) echo "--seeds must be a positive integer" >&2; exit 2 ;;
esac
[ "$SEEDS" -gt 0 ] || { echo "--seeds must be positive" >&2; exit 2; }

case "$SEED_START" in
  ''|*[!0-9]*) echo "--seed-start must be a positive integer" >&2; exit 2 ;;
esac
[ "$SEED_START" -gt 0 ] || { echo "--seed-start must be positive" >&2; exit 2; }

case "$TIMEOUT_SECONDS" in
  ''|*[!0-9]*) echo "--timeout-seconds must be an integer" >&2; exit 2 ;;
esac

mkdir -p "$OUT"
RESULTS="$OUT/results.jsonl"
: > "$RESULTS"

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
GIT_COMMIT="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || printf unknown)"

prepare_isolated_codex_home() {
  [ "$AGENT_CMD" = "__codex__" ] || return 0

  local source_codex_home="${CODEX_HOME:-$HOME/.codex}"
  local auth_file="$source_codex_home/auth.json"
  if [ ! -f "$auth_file" ] && [ -f "$HOME/.codex/auth.json" ]; then
    auth_file="$HOME/.codex/auth.json"
  fi
  [ -f "$auth_file" ] || { echo "missing Codex auth.json; cannot run default codex agent" >&2; exit 1; }

  EVAL_HOME="$(mktemp -d "${TMPDIR:-/tmp}/lodestar-gauntlet-codex-home.XXXXXX")"
  EVAL_CODEX_HOME="$EVAL_HOME/.codex"
  mkdir -p "$EVAL_CODEX_HOME"
  cp "$auth_file" "$EVAL_CODEX_HOME/auth.json"
  trap 'rm -rf "$EVAL_HOME"' EXIT
}

release_facts() {
  cat <<'EOF'
Active objective: prepare Lodestar v1.3.0 for release by aligning evidence claims and release
surfaces after the latest eval findings.

Release facts shared across every arm:
- Version must remain 1.3.0. Do not bump to 1.4.0 and do not create a new major/minor release.
- Pilot evidence is directional, not statistically proven.
- The gap-consolidation result directionally refuted an agent-maintained GAP ledger as the default
  representation for this project.
- Flat summaries plus append-only logs are the recommended default representation.
- GAP remains useful as a lightweight reasoning lens for unmet requirements, open questions, and
  evidence gaps.
- Deterministic tool-maintained structure/ledger is a separate, untested system and must be named
  as untested.
- Align README.md, README.zh.md, CHANGELOG.md, plugin metadata, hooks, templates, project pointer,
  skill bridge, and the skill protocol.
- Keep scope to release-alignment wording and release checks. Do not add product features or do a
  broad eval-harness rewrite.
EOF
}

arm_name() {
  case "$1" in
    A) printf 'bare' ;;
    B) printf 'flat-lodestar' ;;
    C) printf 'placebo-focus' ;;
    D) printf 'agent-gap-ledger' ;;
    E) printf 'tool-gap-ledger' ;;
    *) printf 'unknown' ;;
  esac
}

setup_arm() {
  local repo="$1" arm="$2"
  case "$arm" in
    A)
      {
        printf '# TODO\n\n'
        release_facts
        printf '\n\nNext action: assess findings and list release-alignment surfaces.\n'
      } > "$repo/TODO.md"
      git -C "$repo" add TODO.md
      ;;
    B)
      mkdir -p "$repo/.lodestar"
      {
        printf '# Anchor\n\n'
        printf '## ANCHOR\n'
        printf -- '- Mode: execute\n'
        printf -- '- Goal: align Lodestar v1.3.0 release claims after eval findings\n'
        printf -- '- Done-when: scorer passes; version remains 1.3.0; release checks pass\n'
        printf -- '- Boundaries: no version bump, no broad feature work, no statistical overclaim\n'
        printf -- '- Active gap/question: stale release surfaces may still imply agent-maintained GAP ledger is the default\n'
        printf -- '- Next action: inspect FINDINGS, README, README.zh, CHANGELOG, plugins, hooks, templates, skill protocol\n'
        printf -- '- Drift check: stay on release-alignment wording and verification\n\n'
      } > "$repo/.lodestar/anchor.md"
      {
        printf '# State\n\n'
        release_facts
        printf '\n\n## Open Questions / Gaps\n'
        printf -- '- Which surfaces still contain stale or overbroad GAP-ledger claims?\n'
        printf -- '- Have bilingual README claims stayed consistent?\n'
        printf -- '- Have release checks been run after edits?\n'
      } > "$repo/.lodestar/state.md"
      {
        printf '# Log\n\n'
        printf -- '- initialized flat Lodestar arm with release facts and acceptance criteria\n'
      } > "$repo/.lodestar/log.md"
      git -C "$repo" add -f .lodestar
      ;;
    C)
      {
        printf '# FOCUS\n\n'
        release_facts
        printf '\n\n'
        printf 'Stay focused on the release-alignment task. Avoid scope expansion. Keep the version unchanged. '
        printf 'Use the shared release facts above as the source of orientation. '
        printf 'This file is intentionally plain text: it has no anchor, no state machine, no GAP loop, and no structured ledger.\n'
      } > "$repo/FOCUS.md"
      git -C "$repo" add FOCUS.md
      ;;
    D)
      mkdir -p "$repo/.lodestar"
      {
        printf '# GAP Ledger\n\n'
        release_facts
        printf '\n\n## Protocol\n'
        printf 'Maintain this ledger as the default project state representation. Every open GAP must carry Requirement, Practice, Evidence, Confidence, Breakthrough, and NextAction.\n'
        printf '\n## Open GAPs\n'
        printf -- '- GAP-REL-001\n'
        printf '  - Requirement: release claims reflect the latest eval evidence without overclaiming\n'
        printf '  - Practice: stale docs may still say structure is merely unproven\n'
        printf '  - Evidence: gap-consolidation Run 8 directionally refuted agent-maintained GAP ledger as default\n'
        printf '  - Confidence: medium, pilot only\n'
        printf '  - Breakthrough: use flat summaries by default while keeping GAP as a lens\n'
        printf '  - NextAction: align README, README.zh, CHANGELOG, plugin metadata, hooks, templates, project pointer, skill bridge, and skill protocol\n'
      } > "$repo/.lodestar/gap-ledger.md"
      git -C "$repo" add -f .lodestar/gap-ledger.md
      ;;
    E)
      mkdir -p "$repo/.lodestar/bin"
      {
        printf '{\n'
        printf '  "schema": "release-alignment-gauntlet.gaps.v1",\n'
        printf '  "version_must_remain": "1.3.0",\n'
        printf '  "default_representation": "flat summaries plus append-only logs",\n'
        printf '  "agent_maintained_gap_ledger_default": "directionally_refuted_in_pilot",\n'
        printf '  "tool_maintained_structure": "untested",\n'
        printf '  "gaps": [\n'
        printf '    {"id":"REL-001","question":"Which release surfaces still contain stale GAP-ledger claims?","status":"open","next_action":"inspect and align all required surfaces"},\n'
        printf '    {"id":"REL-002","question":"Have release checks passed after wording edits?","status":"open","next_action":"run bash syntax, CLI, eval smoke, and diff whitespace checks"}\n'
        printf '  ]\n'
        printf '}\n'
      } > "$repo/.lodestar/gaps.json"
      cat > "$repo/.lodestar/bin/gap-ledger" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
file="${1:-.lodestar/gaps.json}"
jq empty "$file"
EOF
      chmod +x "$repo/.lodestar/bin/gap-ledger"
      {
        printf '# Tool-Maintained Gap Ledger\n\n'
        release_facts
        printf '\n\nUse `.lodestar/bin/gap-ledger .lodestar/gaps.json` to validate the ledger after edits. The ledger is tool-maintained; do not handwave invalid JSON.\n'
      } > "$repo/.lodestar/README.md"
      git -C "$repo" add -f .lodestar
      ;;
    *) echo "unknown arm: $arm" >&2; exit 2 ;;
  esac

  git -C "$repo" -c user.email=eval@example.test -c user.name="Eval Fixture" commit -qm "arm setup $arm"
}

orientation_files() {
  case "$1" in
    A) printf 'TODO.md\n' ;;
    B) printf '.lodestar/anchor.md\n.lodestar/state.md\n.lodestar/log.md\n' ;;
    C) printf 'FOCUS.md\n' ;;
    D) printf '.lodestar/gap-ledger.md\n' ;;
    E) printf '.lodestar/README.md\n.lodestar/gaps.json\n' ;;
  esac
}

memory_paths_for_commit() {
  case "$1" in
    A) printf 'TODO.md\n' ;;
    B|D|E) printf '.lodestar\n' ;;
    C) printf 'FOCUS.md\n' ;;
  esac
}

compose_prompt() {
  local repo="$1" arm="$2" turn_file="$3" out_file="$4"
  {
    printf '# Release Alignment Gauntlet Turn\n\n'
    printf 'You are running inside an isolated benchmark fixture repo at `%s`.\n' "$repo"
    printf 'This is a fresh-context invocation; prior chat context is intentionally unavailable.\n'
    printf 'Do not commit, tag, push, create branches, or modify the original Lodestar repository. Leave product changes in this fixture working tree.\n'
    printf 'You may edit files and run local verification commands.\n\n'
    printf 'Benchmark scope control: follow the current user turn literally. Do not do broad repo sweeps beyond the surfaces named by the turn plus evals/FINDINGS.md. Before turn 5, prefer assessment over edits. Before turn 7, do not run full release verification unless it is necessary to unblock the current turn.\n\n'
    printf 'Arm: %s (%s).\n' "$arm" "$(arm_name "$arm")"
    printf 'Before acting, read these arm-orientation file(s) from the fixture repo and use them only as orientation, not as scoring truth:\n'
    orientation_files "$arm" | sed 's/^/- /'
    printf '\nThe external scorer, not the orientation files, decides whether the run passes.\n\n'
    printf '## User Turn\n\n'
    cat "$turn_file"
    printf '\n'
  } > "$out_file"
}

commit_memory_updates() {
  local repo="$1" arm="$2"
  local path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    [ -e "$repo/$path" ] || continue
    git -C "$repo" add -f "$path" >/dev/null 2>&1 || true
  done < <(memory_paths_for_commit "$arm")

  if ! git -C "$repo" diff --cached --quiet; then
    git -C "$repo" -c user.email=eval@example.test -c user.name="Eval Fixture" commit -qm "arm memory update" || true
  fi
}

run_with_timeout() {
  local stdin_file="${RUN_WITH_TIMEOUT_STDIN_FILE:-}"
  if [ "$TIMEOUT_SECONDS" -eq 0 ]; then
    if [ -n "$stdin_file" ]; then
      "$@" < "$stdin_file"
    else
      "$@"
    fi
  elif command -v gtimeout >/dev/null 2>&1; then
    if [ -n "$stdin_file" ]; then
      gtimeout "$TIMEOUT_SECONDS" "$@" < "$stdin_file"
    else
      gtimeout "$TIMEOUT_SECONDS" "$@"
    fi
  elif command -v timeout >/dev/null 2>&1; then
    if [ -n "$stdin_file" ]; then
      timeout "$TIMEOUT_SECONDS" "$@" < "$stdin_file"
    else
      timeout "$TIMEOUT_SECONDS" "$@"
    fi
  else
    if [ -n "$stdin_file" ]; then
      "$@" < "$stdin_file" &
    else
      "$@" &
    fi
    local pid="$!"
    (
      sleep "$TIMEOUT_SECONDS"
      if kill -0 "$pid" 2>/dev/null; then
        pkill -TERM -P "$pid" 2>/dev/null || true
        kill -TERM "$pid" 2>/dev/null || true
        sleep 5
        pkill -KILL -P "$pid" 2>/dev/null || true
        kill -KILL "$pid" 2>/dev/null || true
      fi
    ) &
    local watcher="$!"
    wait "$pid"
    local status="$?"
    kill "$watcher" 2>/dev/null || true
    wait "$watcher" 2>/dev/null || true
    return "$status"
  fi
}

expand_agent_cmd() {
  local cmd="$1" repo="$2" last="$3" json="$4" stderr="$5" prompt="$6"
  cmd="${cmd//\{\{repo\}\}/$repo}"
  cmd="${cmd//\{\{last\}\}/$last}"
  cmd="${cmd//\{\{json\}\}/$json}"
  cmd="${cmd//\{\{stderr\}\}/$stderr}"
  cmd="${cmd//\{\{prompt\}\}/$prompt}"
  printf '%s' "$cmd"
}

run_agent_turn() {
  local repo="$1" prompt_file="$2" json_file="$3" stderr_file="$4" last_file="$5"
  local exit_code
  set +e
  if [ "$AGENT_CMD" = "__codex__" ]; then
    HOME="$EVAL_HOME" CODEX_HOME="$EVAL_CODEX_HOME" RUN_WITH_TIMEOUT_STDIN_FILE="$prompt_file" \
    run_with_timeout codex exec -C "$repo" --ignore-user-config --ignore-rules \
      -s danger-full-access --ephemeral \
      --disable chronicle --disable memories --disable plugins --disable apps --disable multi_agent \
      --config 'model_reasoning_effort="low"' \
      --json -o "$last_file" - \
      > "$json_file" 2> "$stderr_file"
    exit_code=$?
  else
    local cmd
    cmd="$(expand_agent_cmd "$AGENT_CMD" "$repo" "$last_file" "$json_file" "$stderr_file" "$prompt_file")"
    ( cd "$repo" && eval "$cmd" ) < "$prompt_file" > "$json_file" 2> "$stderr_file"
    exit_code=$?
  fi
  set -e
  return "$exit_code"
}

prompt_count() {
  find "$TASK_DIR/turns" -type f -name '*.md' | wc -l | tr -d ' '
}

json_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '"%s"' "$s"
}

write_report() {
  {
    printf '# Release Alignment Gauntlet Pilot Report\n\n'
    printf -- '- run_id: %s\n' "$RUN_ID"
    printf -- '- date_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf -- '- repo_commit: %s\n' "$GIT_COMMIT"
    printf -- '- arms: %s\n' "$ARMS"
    printf -- '- seeds_per_arm: %s\n' "$SEEDS"
    printf -- '- seed_start: %s\n' "$SEED_START"
    printf -- '- turns_per_run: %s\n' "$(prompt_count)"
    if [ "$AGENT_CMD" = "__codex__" ]; then
      printf -- '- agent: codex exec, fresh context per turn\n'
      printf -- '- agent_isolation: temporary HOME/CODEX_HOME with auth.json only\n'
    else
      printf -- '- agent_cmd: `%s`\n' "$AGENT_CMD"
    fi
    printf -- '- run_tests: %s\n\n' "$RUN_TESTS"
    printf '## Objective Results\n\n'
    printf '| Arm | Runs | Pass | Avg score |\n'
    printf '|---|---:|---:|---:|\n'
    jq -r '
      group_by(.arm)[] |
      {arm: .[0].arm, runs: length, pass: map(select(.done_when_passed == true)) | length, avg: (map(.score) | add / length)} |
      "| \(.arm) | \(.runs) | \(.pass) | \((.avg * 10 | round) / 10) |"
    ' <(jq -s '.' "$RESULTS")
    printf '\n## Caveat\n\n'
    printf 'This is a real-agent pilot if agent output artifacts exist, but it remains below the preregistered n>=5 threshold. Treat directionality as anecdotal until more seeds and blind judging are complete.\n'
  } > "$OUT/report.md"
}

SEED_END=$((SEED_START + SEEDS - 1))

printf 'task=release-alignment-gauntlet run_id=%s arms=%s seeds=%s seed_start=%s out=%s\n' "$RUN_ID" "$ARMS" "$SEEDS" "$SEED_START" "$OUT"

IFS=',' read -ra ARM_LIST <<< "$ARMS"
for arm in "${ARM_LIST[@]}"; do
  case "$arm" in A|B|C|D|E) ;; *) echo "unknown arm: $arm" >&2; exit 2 ;; esac
done

prepare_isolated_codex_home

for arm in "${ARM_LIST[@]}"; do
  pass_count=0
  for seed in $(seq "$SEED_START" "$SEED_END"); do
    work="$OUT/work/$arm/seed-$seed"
    bash "$TASK_DIR/seed_fixture.sh" "$work" "$seed" >/dev/null
    repo="$work/repo"
    setup_arm "$repo" "$arm"

    turn=0
    failed_turns=0
    for turn_file in "$TASK_DIR"/turns/*.md; do
      turn=$((turn + 1))
      turn_id="$(printf '%02d' "$turn")-$(basename "$turn_file" .md)"
      prompt_file="$work/prompts/$turn_id.full.md"
      json_file="$work/transcripts/$turn_id.codex.jsonl"
      stderr_file="$work/transcripts/$turn_id.stderr"
      last_file="$work/transcripts/$turn_id.last.md"

      compose_prompt "$repo" "$arm" "$turn_file" "$prompt_file"
      printf '%s\n' "turn=$turn arm=$arm seed=$seed before" > "$work/snapshots/$turn_id.before.status"
      git -C "$repo" status --short >> "$work/snapshots/$turn_id.before.status"

      if ! run_agent_turn "$repo" "$prompt_file" "$json_file" "$stderr_file" "$last_file"; then
        failed_turns=$((failed_turns + 1))
        printf 'agent command failed for arm=%s seed=%s turn=%s; continuing\n' "$arm" "$seed" "$turn" >&2
      fi

      commit_memory_updates "$repo" "$arm"

      printf '%s\n' "turn=$turn arm=$arm seed=$seed after" > "$work/snapshots/$turn_id.after.status"
      git -C "$repo" status --short >> "$work/snapshots/$turn_id.after.status"
    done

    git -C "$repo" diff > "$work/final/diff.patch"
    if [ "$RUN_TESTS" -eq 1 ]; then
      bash "$TASK_DIR/score.sh" "$repo" --run-tests > "$work/final/scorer.json"
    else
      bash "$TASK_DIR/score.sh" "$repo" > "$work/final/scorer.json"
    fi

    done_when="$(jq -r '.done_when_passed' "$work/final/scorer.json")"
    score="$(jq -r '.score' "$work/final/scorer.json")"
    [ "$done_when" = "true" ] && pass_count=$((pass_count + 1))

    printf '{"run_id":%s,"task":"release-alignment-gauntlet","arm":"%s","arm_name":"%s","seed":%s,"turns":%s,"failed_turns":%s,"done_when_passed":%s,"score":%s,"scorer":%s,"work":%s}\n' \
      "$(json_string "$RUN_ID")" "$arm" "$(arm_name "$arm")" "$seed" "$(prompt_count)" "$failed_turns" "$done_when" "$score" \
      "$(json_string "$work/final/scorer.json")" "$(json_string "$work")" >> "$RESULTS"
  done
  printf 'arm %s (%s): pass@%s = %s/%s\n' "$arm" "$(arm_name "$arm")" "$(prompt_count)" "$pass_count" "$SEEDS"
done

write_report
printf 'results: %s\n' "$RESULTS"
printf 'report: %s\n' "$OUT/report.md"

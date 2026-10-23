#!/usr/bin/env bash

set -euo pipefail

LODESTAR_HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LODESTAR_PLAN_TOOL="$LODESTAR_HOOKS_DIR/../skills/lodestar/scripts/lodestar-plan"

project_root() {
  local start current boundary
  start="$(pwd -P)"
  current="$start"
  boundary="$(git rev-parse --show-toplevel 2>/dev/null || printf '/')"
  # Prefer the nearest initialized project, without escaping a Git worktree.
  while :; do
    if [ -d "$current/.lodestar" ]; then
      printf '%s\n' "$current"
      return
    fi
    [ "$current" = "$boundary" ] || [ "$current" = / ] && break
    current="$(dirname "$current")"
  done
  printf '%s\n' "$start"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

read_payload() {
  # Hosts pipe a JSON payload on stdin. A terminal means a manual run: no payload.
  if [ -t 0 ]; then
    printf ''
  else
    cat
  fi
}

payload_session_id() {
  local payload="$1" id="default" re='"session_id"[[:space:]]*:[[:space:]]*"([^"]*)"'
  if [[ "$payload" =~ $re ]]; then
    id="${BASH_REMATCH[1]}"
  fi
  id="${id//[^A-Za-z0-9._-]/_}"
  printf '%s\n' "${id:-default}"
}

is_first_stop() {
  # Only a known first stop may request another turn. Missing/unknown flags fail open.
  # Match JSON syntax, not an escaped mention inside last_assistant_message.
  local payload="$1"
  local first_stop='[,{][[:space:]]*"stop_hook_active"[[:space:]]*:[[:space:]]*false[[:space:]]*[,}]'
  [[ "$payload" =~ $first_stop ]]
}

# Per-session runtime markers (timestamps and a counter, never content) live outside the
# project so hooks stay read-only for project files. Every write is best-effort: a host
# sandbox that blocks them degrades to the legacy behavior.
runtime_dir() {
  local root="$1" base key
  base="${LODESTAR_RUNTIME_DIR:-${TMPDIR:-/tmp}/lodestar-runtime-$(id -u 2>/dev/null || printf 0)}"
  key="$(printf '%s' "$root" | cksum | awk '{print $1}')"
  printf '%s/%s\n' "${base%/}" "$key"
}

prune_runtime() {
  local base="${LODESTAR_RUNTIME_DIR:-${TMPDIR:-/tmp}/lodestar-runtime-$(id -u 2>/dev/null || printf 0)}"
  [ -d "$base" ] || return 0
  find "$base" -type f -mtime +2 -exec rm -f {} + 2>/dev/null || true
}

read_count() {
  local file="$1" count=0
  [ -f "$file" ] && count="$(cat "$file" 2>/dev/null || printf 0)"
  case "$count" in ''|*[!0-9]*) count=0 ;; esac
  printf '%s\n' "$count"
}

mark_turn() {
  # UserPromptSubmit: open a new turn and count turns since the last save or reminder.
  local root="$1" session="$2" dir count
  dir="$(runtime_dir "$root")"
  mkdir -p "$dir" 2>/dev/null || return 0
  touch "$dir/$session.turn" 2>/dev/null || return 0
  count="$(read_count "$dir/$session.count")"
  printf '%s\n' "$((count + 1))" > "$dir/$session.count" 2>/dev/null || true
}

plan_dir_for_root() {
  # Print the planning workspace for this root, if one exists. Never fails.
  local root="$1"
  [ -x "$LODESTAR_PLAN_TOOL" ] || return 0
  "$LODESTAR_PLAN_TOOL" locate --root "$root" 2>/dev/null || true
}

state_saved_since() {
  local root="$1" marker="$2" plan
  if [ -n "$(find "$root/.lodestar" -maxdepth 1 -type f -name '*.md' -newer "$marker" 2>/dev/null | head -1)" ]; then
    return 0
  fi
  plan="$(plan_dir_for_root "$root")"
  [ -n "$plan" ] && [ -n "$(find "$plan" -type f -name '*.md' -newer "$marker" 2>/dev/null | head -1)" ]
}

stop_gate() {
  # Print "block" when the Stop handoff check should run, else "allow".
  # LODESTAR_STOP_EVERY=N: at most one check per N turns without a save (default 3);
  # 1 checks every unsaved turn; 0 disables the check.
  local root="$1" session="$2" every="${LODESTAR_STOP_EVERY:-3}" dir marker count
  case "$every" in ''|*[!0-9]*) every=3 ;; esac
  if [ "$every" -eq 0 ]; then
    printf 'allow\n'
    return
  fi
  dir="$(runtime_dir "$root")"
  marker="$dir/$session.turn"
  if [ ! -f "$marker" ]; then
    # No UserPromptSubmit tracking (older config or host): keep the legacy check.
    printf 'block\n'
    return
  fi
  if state_saved_since "$root" "$marker"; then
    printf '0\n' > "$dir/$session.count" 2>/dev/null || true
    printf 'allow\n'
    return
  fi
  count="$(read_count "$dir/$session.count")"
  if [ "$count" -ge "$every" ]; then
    printf '0\n' > "$dir/$session.count" 2>/dev/null || true
    printf 'block\n'
  else
    printf 'allow\n'
  fi
}

pretool_first_in_turn() {
  # Inject the drift check before the first mutating tool of a turn, not before every call.
  local root="$1" session="$2" dir marker seen
  dir="$(runtime_dir "$root")"
  marker="$dir/$session.turn"
  seen="$dir/$session.pretool"
  [ -f "$marker" ] || return 0
  if [ -f "$seen" ] && [ -n "$(find "$seen" -newer "$marker" 2>/dev/null)" ]; then
    return 1
  fi
  touch "$seen" 2>/dev/null || true
  return 0
}

anchor_brief() {
  local anchor="$1" brief
  [ -f "$anchor" ] || return 0
  brief="$(grep -E '^[[:space:]]*[-*][[:space:]].*(Mode|Goal|Done-when|Next action)' "$anchor" 2>/dev/null | head -6 || true)"
  if [ -z "$brief" ]; then
    brief="$(grep -E 'Mode|Goal|Done-when' "$anchor" 2>/dev/null | head -6 || true)"
  fi
  printf '%s\n' "$brief"
}

file_excerpt() {
  # file_excerpt <label> <path> <limit> [headtail|tail]
  # headtail keeps the start and end of current-state files; tail keeps the newest log entries.
  local label="$1" path="$2" limit="${3:-2000}" mode="${4:-headtail}" text half utf8_locale
  local slice rest sep=$'\n## '
  local -x LC_ALL="${LC_ALL:-${LC_CTYPE:-${LANG:-C}}}"
  # Bash substrings use the active locale. Never split a UTF-8 code point when
  # a host starts hooks with LC_ALL=C (common in headless runners).
  if [[ "$(locale charmap 2>/dev/null || true)" != UTF-8 ]]; then
    utf8_locale="$(locale -a 2>/dev/null | awk 'tolower($0) ~ /utf-?8/ {print; exit}' || true)"
    [ -z "$utf8_locale" ] || LC_ALL="$utf8_locale"
  fi
  if [ -f "$path" ]; then
    text="$(cat "$path")"
    printf '## %s\n' "$label"
    if [ "${#text}" -le "$limit" ]; then
      printf '%s\n\n' "$text"
    elif [[ "$(locale charmap 2>/dev/null || true)" != UTF-8 ]]; then
      printf '[OMITTED: no UTF-8 locale; read %s before relying on this state.]\n\n' "$path"
    elif [ "$mode" = tail ]; then
      slice="${text: -limit}"
      rest="${slice#*"$sep"}"
      # Start at a whole entry when one begins in the first half of the slice.
      if [ "$rest" != "$slice" ] && [ "${#rest}" -ge $((limit / 2)) ]; then
        slice="## $rest"
      fi
      printf '[EARLIER ENTRIES OMITTED: read %s before relying on older history.]\n%s\n\n' \
        "$path" "$slice"
    else
      half=$((limit / 2))
      printf '%s\n[TRUNCATED: read the omitted middle of %s before relying on this state.]\n%s\n\n' \
        "${text:0:half}" "$path" "${text: -half}"
    fi
  else
    printf '## %s\nmissing: %s\n\n' "$label" "$path"
  fi
}

turn_context() {
  # The per-message check delivered by UserPromptSubmit (also reused by the portable eval driver).
  local root="$1" plan ideas
  plan="$(plan_dir_for_root "$root")"
  if [ -n "$plan" ]; then
    ideas="the planning workspace ideas file (${plan#"$root"/}/ideas.md)"
  else
    ideas=".lodestar/state.md open questions"
  fi
  cat <<CTX
<LODESTAR_TURN>
Silent orientation: do not restate it. Before replying, place this message against the anchor:
on-track | new idea | goal change | material conflict.
- New idea or plan fragment outside the focus: capture it in $ideas and continue;
  in explore mode it is input, not drift.
- Explicit goal correction: update the Anchor directly. Inferred change: ask before re-anchoring.
- Material conflict with the Goal, a recorded decision, or a first-principles constraint: say so
  once, briefly, with evidence. If the user insists, comply, record the override with its
  compensation, and do not re-litigate it without new evidence.
Persist material changes during this turn; trivial turns need no write.

ANCHOR (brief):
$(anchor_brief "$root/.lodestar/anchor.md")
</LODESTAR_TURN>
CTX
}

plan_summary() {
  # Compact planning-workspace summary (paths and counts only), or nothing.
  local root="$1" plan
  plan="$(plan_dir_for_root "$root")"
  [ -n "$plan" ] || return 0
  "$LODESTAR_PLAN_TOOL" summary --root "$root" --plan-dir "$plan" 2>/dev/null || true
}

anchor_excerpt() {
  local root="$1" state_dir="$root/.lodestar" summary
  if [ ! -d "$state_dir" ]; then
    cat <<EOF
Lodestar is not initialized for this project root:
$root

If this project needs goal anchoring, run: lodestar init "$root"
EOF
    return
  fi

  cat <<EOF
<LODESTAR_CONTEXT>
Use this context silently; do not prepend a goal-restatement to deliverables. Explain the
orientation mechanism when the user asks about it, and surface real conflicts when needed.
Hold the real goal, not merely the written goal. The Anchor is a working commitment: resist recency
noise, but if repeated or strong evidence suggests the real goal or priority changed, ask
whether to re-anchor the primary Goal, raise the priority of a branch goal, or park the tangent. Never
silently rewrite the Anchor from one or two side remarks.
Project root: $root
Authoritative state dir: .lodestar/
Read order: anchor.md -> domain.md -> state.md -> log.md
Read any omitted content before making decisions that depend on it. Storage budgets are not
injection budgets. Persist material changes during work, before context pressure can erase them;
PreCompact cannot ask the model to perform a save. An explicit user goal correction authorizes
updating the Anchor; ask for confirmation only when inferring a change.

EOF
  file_excerpt "ANCHOR (.lodestar/anchor.md)" "$state_dir/anchor.md" 2000
  file_excerpt "DOMAIN MAP (.lodestar/domain.md)" "$state_dir/domain.md" 1500
  file_excerpt "STATE (.lodestar/state.md)" "$state_dir/state.md" 3000
  file_excerpt "LOG (.lodestar/log.md, newest entries)" "$state_dir/log.md" 2000 tail
  summary="$(plan_summary "$root")"
  [ -z "$summary" ] || printf '%s\n\n' "$summary"
  cat <<EOF
</LODESTAR_CONTEXT>
EOF
}

handoff_excerpt() {
  local root="$1" state_dir="$root/.lodestar" summary
  if [ ! -d "$state_dir" ]; then
    printf 'LODESTAR_HANDOFF: no .lodestar/ state for %s\n' "$root"
    return
  fi

  cat <<EOF
<LODESTAR_HANDOFF>
Use this context silently without a goal-restating preamble. Before acting, identify which Goal
or open gap/question your work
serves. If evidence suggests the real goal or priority has changed, ask whether to re-anchor the
primary Goal, raise the priority of a branch goal, or park the tangent. After acting, return state,
evidence, decision, material gap/question, and next-action updates.
Read omitted content before relying on a truncated excerpt. Follow explicit user goal corrections
without asking for redundant confirmation. Return a handoff to the parent; do not overwrite
shared project state unless the parent assigned you ownership of those files.

EOF
  file_excerpt "ANCHOR" "$state_dir/anchor.md" 2000
  file_excerpt "DOMAIN" "$state_dir/domain.md" 1500
  file_excerpt "STATE" "$state_dir/state.md" 3000
  file_excerpt "LOG (newest entries)" "$state_dir/log.md" 2000 tail
  summary="$(plan_summary "$root")"
  [ -z "$summary" ] || printf '%s\n\n' "$summary"
  cat <<EOF
</LODESTAR_HANDOFF>
EOF
}

emit_additional_context() {
  local event="$1" context="$2" escaped
  escaped="$(json_escape "$context")"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "$event",
    "additionalContext": "$escaped"
  }
}
EOF
}

emit_block() {
  local escaped
  escaped="$(json_escape "$1")"
  cat <<EOF
{
  "decision": "block",
  "reason": "$escaped"
}
EOF
}

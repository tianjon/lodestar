#!/usr/bin/env bash

set -euo pipefail

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

file_excerpt() {
  local label="$1" path="$2" limit="${3:-2000}" text half utf8_locale
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
    else
      half=$((limit / 2))
      printf '%s\n[TRUNCATED: read the omitted middle of %s before relying on this state.]\n%s\n\n' \
        "${text:0:half}" "$path" "${text: -half}"
    fi
  else
    printf '## %s\nmissing: %s\n\n' "$label" "$path"
  fi
}

anchor_excerpt() {
  local root="$1" state_dir="$root/.lodestar"
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
  file_excerpt "LOG (.lodestar/log.md)" "$state_dir/log.md" 1000
  cat <<EOF
</LODESTAR_CONTEXT>
EOF
}

handoff_excerpt() {
  local root="$1" state_dir="$root/.lodestar"
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
  file_excerpt "LOG" "$state_dir/log.md" 1000
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

emit_handoff_continuation() {
  local message="$1" escaped payload first_stop
  payload="$(cat)"
  # Only a known first stop may request another turn. Missing/unknown flags fail open.
  # Match JSON syntax, not an escaped mention inside last_assistant_message.
  first_stop='[,{][[:space:]]*"stop_hook_active"[[:space:]]*:[[:space:]]*false[[:space:]]*[,}]'
  if ! [[ "$payload" =~ $first_stop ]]; then
    printf '{}\n'
    return
  fi
  escaped="$(json_escape "$message")"
  cat <<EOF
{
  "decision": "block",
  "reason": "$escaped"
}
EOF
}

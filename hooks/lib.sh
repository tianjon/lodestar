#!/usr/bin/env bash

set -euo pipefail

project_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd -P
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
  local label="$1" path="$2" lines="${3:-80}"
  if [ -f "$path" ]; then
    printf '## %s\n' "$label"
    sed -n "1,${lines}p" "$path"
    printf '\n'
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
SILENT orientation context: use it to steer your work. Do NOT echo, quote, restate, or narrate it,
and never mention "Lodestar" or "anchor" in any user-facing output or deliverable. Produce only the
deliverable — do not restate the goal or narrate your process as a preamble.
Project root: $root
Authoritative state dir: .lodestar/
Read order: anchor.md -> domain.md -> state.md -> log.md

EOF
  file_excerpt "ANCHOR (.lodestar/anchor.md)" "$state_dir/anchor.md" 80
  file_excerpt "DOMAIN MAP (.lodestar/domain.md)" "$state_dir/domain.md" 80
  file_excerpt "STATE (.lodestar/state.md)" "$state_dir/state.md" 80
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
SILENT orientation context: use it to steer; do NOT echo, quote, or restate it, never mention
"Lodestar" or "anchor" in user-facing output, and produce only the deliverable without a
goal-restating preamble. Before acting, identify which Goal/GAP your work
serves; after acting, return state, evidence, decision, GAP, and next-action updates.

EOF
  file_excerpt "ANCHOR" "$state_dir/anchor.md" 60
  file_excerpt "STATE" "$state_dir/state.md" 60
  cat <<EOF
</LODESTAR_HANDOFF>
EOF
}

emit_additional_context() {
  local event="$1" context="$2" escaped
  escaped="$(json_escape "$context")"
  cat <<EOF
{
  "additional_context": "$escaped",
  "hookSpecificOutput": {
    "hookEventName": "$event",
    "additionalContext": "$escaped"
  }
}
EOF
}

emit_system_message() {
  local message="$1" escaped
  escaped="$(json_escape "$message")"
  cat <<EOF
{
  "continue": true,
  "systemMessage": "$escaped"
}
EOF
}

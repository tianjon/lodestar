#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1" pattern="$2"
  grep -Fq "$pattern" "$file" || fail "$file does not contain: $pattern"
}

assert_file_not_contains() {
  local file="$1" pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    fail "$file unexpectedly contains: $pattern"
  fi
}

test_init_escapes_project_name_for_templates() {
  local dir="$TMPDIR/foo&bar"
  mkdir -p "$dir"

  "$ROOT/bin/lodestar" init "$dir" >/dev/null

  assert_file_contains "$dir/.memory/working.md" "foo&bar"
  assert_file_contains "$dir/.memory/consolidated.md" "foo&bar"
  assert_file_not_contains "$dir/.memory/working.md" "<PROJECT>"
  assert_file_not_contains "$dir/.memory/consolidated.md" "<PROJECT>"
}

test_init_marks_memory_private_by_default() {
  local dir="$TMPDIR/private-default"
  mkdir -p "$dir"

  "$ROOT/bin/lodestar" init "$dir" >/dev/null

  assert_file_contains "$dir/.gitignore" ".memory/"
}

test_status_counts_utf8_characters_not_bytes() {
  local dir="$TMPDIR/unicode-budget"
  mkdir -p "$dir"
  "$ROOT/bin/lodestar" init "$dir" >/dev/null

  {
    sed -n '1,13p' "$ROOT/skills/lodestar/references/templates/working.md"
    perl -Mutf8 -CS -e 'print "汉" x 30000, "\n---\n"'
  } > "$dir/.memory/working.md"

  local status
  status="$("$ROOT/bin/lodestar" status "$dir")"
  if grep -Fq "over budget" <<<"$status"; then
    fail "UTF-8 character budget was counted as bytes: $status"
  fi
}

test_protocol_documents_sensitive_data_boundary() {
  assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "Sensitive data boundary"
  assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "redacted-summary"
  assert_file_contains "$ROOT/skills/lodestar/references/project-pointer.md" "Do not record secrets"
}

test_protocol_documents_orientation_ontology() {
  assert_file_contains "$ROOT/skills/lodestar/references/ontology.md" "Orientation Core"
  assert_file_contains "$ROOT/skills/lodestar/references/ontology.md" "Evidence supports Practice"
  assert_file_contains "$ROOT/skills/lodestar/references/skill-bridge.md" "Superpowers"
  assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "Protocol 5"
}

test_templates_include_mode_evidence_and_decisions() {
  local dir="$TMPDIR/orientation-template"
  mkdir -p "$dir"

  "$ROOT/bin/lodestar" init "$dir" >/dev/null

  assert_file_contains "$dir/.memory/working.md" "模式 Mode"
  assert_file_contains "$dir/.memory/working.md" "证据 Evidence"
  assert_file_contains "$dir/.memory/working.md" "决策 Decision"
  assert_file_contains "$dir/.memory/consolidated.md" "决策日志 Decision Log"

  local status
  status="$("$ROOT/bin/lodestar" status "$dir")"
  if ! grep -Fq "模式 Mode" <<<"$status"; then
    fail "status did not show ANCHOR Mode: $status"
  fi
}

test_skill_remains_self_contained() {
  assert_file_not_contains "$ROOT/skills/lodestar/SKILL.md" "bin/lodestar"
  assert_file_not_contains "$ROOT/skills/lodestar/references/project-pointer.md" "bin/lodestar"
}

test_maintainer_docs_name_bash_not_posix() {
  assert_file_contains "$ROOT/AGENTS.md" "plain bash"
  assert_file_not_contains "$ROOT/AGENTS.md" "plain POSIX shell"
}

test_copy_install_is_idempotent_and_marked_managed() {
  local home="$TMPDIR/install-home"
  mkdir -p "$home/.codex"

  HOME="$home" FORCE_CODEX=1 "$ROOT/install.sh" --copy --codex >/dev/null
  HOME="$home" FORCE_CODEX=1 "$ROOT/install.sh" --copy --codex >/dev/null

  assert_file_contains "$home/.codex/skills/lodestar/SKILL.md" "name: lodestar"
  assert_file_contains "$home/.codex/skills/lodestar/.lodestar-install-source" "managed-by-lodestar-install"
}

test_install_refuses_to_overwrite_unmanaged_existing_skill() {
  local home="$TMPDIR/unmanaged-home"
  local dest="$home/.codex/skills/lodestar"
  mkdir -p "$dest" "$home/.codex"
  printf 'local edits\n' > "$dest/SKILL.md"

  if HOME="$home" FORCE_CODEX=1 "$ROOT/install.sh" --copy --codex >/dev/null 2>&1; then
    fail "install overwrote an unmanaged existing skill without --force"
  fi

  assert_file_contains "$dest/SKILL.md" "local edits"
}

test_force_allows_replacing_unmanaged_existing_skill() {
  local home="$TMPDIR/force-home"
  local dest="$home/.codex/skills/lodestar"
  mkdir -p "$dest" "$home/.codex"
  printf 'local edits\n' > "$dest/SKILL.md"

  HOME="$home" FORCE_CODEX=1 "$ROOT/install.sh" --copy --codex --force >/dev/null

  assert_file_contains "$dest/SKILL.md" "name: lodestar"
  assert_file_contains "$dest/.lodestar-install-source" "managed-by-lodestar-install"
}

test_init_escapes_project_name_for_templates
test_init_marks_memory_private_by_default
test_status_counts_utf8_characters_not_bytes
test_protocol_documents_sensitive_data_boundary
test_protocol_documents_orientation_ontology
test_templates_include_mode_evidence_and_decisions
test_skill_remains_self_contained
test_maintainer_docs_name_bash_not_posix
test_copy_install_is_idempotent_and_marked_managed
test_install_refuses_to_overwrite_unmanaged_existing_skill
test_force_allows_replacing_unmanaged_existing_skill

printf 'ok - lodestar CLI and docs\n'

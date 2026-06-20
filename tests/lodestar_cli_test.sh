#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
HOOK_MARKER="LODESTAR_HOOK_MANAGED=1"
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

assert_tree_not_contains() {
  local root="$1" pattern="$2" out="$3"
  if grep -R -n -F --exclude-dir=.git -- "$pattern" "$root" > "$out"; then
    cat "$out" >&2
    fail "tree unexpectedly contains: $pattern"
  fi
}

assert_path_exists() {
  [ -e "$1" ] || fail "missing path: $1"
}

assert_path_absent() {
  [ ! -e "$1" ] || fail "unexpected path exists: $1"
}

test_init_creates_lodestar_namespace_only() {
  local dir="$TMPDIR/foo&bar"

  "$ROOT/bin/lodestar" init "$dir" >/dev/null

  assert_path_exists "$dir"
  assert_path_exists "$dir/.lodestar/anchor.md"
  assert_path_exists "$dir/.lodestar/domain.md"
  assert_path_exists "$dir/.lodestar/state.md"
  assert_path_exists "$dir/.lodestar/log.md"
  assert_path_exists "$dir/.lodestar/archive"

  assert_file_contains "$dir/.lodestar/anchor.md" "foo&bar"
  assert_file_contains "$dir/.lodestar/domain.md" "foo&bar"
  assert_file_contains "$dir/.lodestar/state.md" "foo&bar"
  assert_file_contains "$dir/.lodestar/log.md" "foo&bar"
  assert_file_not_contains "$dir/.lodestar/anchor.md" "<PROJECT>"
  assert_file_contains "$dir/.gitignore" ".lodestar/"
}

test_full_profile_includes_gap_decision_and_domain_scaffolds() {
  local dir="$TMPDIR/full-profile"
  mkdir -p "$dir"

  "$ROOT/bin/lodestar" init "$dir" --profile full >/dev/null

  assert_file_contains "$dir/.lodestar/domain.md" "Ubiquitous Language"
  assert_file_contains "$dir/.lodestar/domain.md" "Bounded Contexts"
  assert_file_contains "$dir/.lodestar/state.md" "Decision Log"
  assert_file_contains "$dir/.lodestar/log.md" "breakthrough"
}

test_status_counts_utf8_characters_not_bytes() {
  local dir="$TMPDIR/unicode-budget"
  mkdir -p "$dir"
  "$ROOT/bin/lodestar" init "$dir" >/dev/null

  {
    sed -n '1,8p' "$ROOT/skills/lodestar/references/templates/minimal/log.md"
    perl -Mutf8 -CS -e 'print "汉" x 30000, "\n"'
  } > "$dir/.lodestar/log.md"

  local status
  status="$("$ROOT/bin/lodestar" status "$dir")"
  if grep -Fq "over budget" <<<"$status"; then
    fail "UTF-8 character budget was counted as bytes: $status"
  fi
  if ! grep -Fq "模式 Mode" <<<"$status"; then
    fail "status did not show ANCHOR Mode: $status"
  fi
  if ! grep -Fq "Codex" <<<"$status"; then
    fail "status did not show hook status: $status"
  fi
}

test_hooks_install_status_and_uninstall() {
  local dir="$TMPDIR/hooks"
  mkdir -p "$dir"
  "$ROOT/bin/lodestar" init "$dir" --hooks both >/dev/null

  assert_file_contains "$dir/.codex/hooks.json" "$HOOK_MARKER"
  assert_file_contains "$dir/.claude/settings.json" "$HOOK_MARKER"
  assert_file_contains "$dir/.codex/hooks.json" "session-start"
  assert_file_contains "$dir/.claude/settings.json" "pre-tool-use"

  local status
  status="$("$ROOT/bin/lodestar" hooks status "$dir")"
  grep -Fq "configured" <<<"$status" || fail "hooks status did not show configured hooks: $status"

  "$ROOT/bin/lodestar" hooks uninstall "$dir" --target both >/dev/null
  assert_path_absent "$dir/.codex/hooks.json"
  assert_path_absent "$dir/.claude/settings.json"
}

test_hooks_managed_marker_is_not_repo_path_dependent() {
  local src="$TMPDIR/portable-src"
  local dir="$TMPDIR/portable-project"
  mkdir -p "$src" "$dir"

  cp -R "$ROOT/bin" "$ROOT/hooks" "$ROOT/skills" "$ROOT/install.sh" "$src/"
  chmod +x "$src/bin/lodestar" "$src/install.sh" "$src/hooks/"*

  case "$src" in
    *lodestar*) fail "portable test source path unexpectedly contains lodestar: $src" ;;
  esac

  "$src/bin/lodestar" init "$dir" --hooks both >/dev/null
  assert_file_contains "$dir/.codex/hooks.json" "$HOOK_MARKER"
  assert_file_contains "$dir/.claude/settings.json" "$HOOK_MARKER"

  local status
  status="$("$src/bin/lodestar" hooks status "$dir")"
  grep -Fq "Codex        configured" <<<"$status" || fail "Codex hook was not recognized as managed: $status"
  grep -Fq "Claude       configured" <<<"$status" || fail "Claude hook was not recognized as managed: $status"

  "$src/bin/lodestar" hooks install "$dir" --target both >/dev/null
  "$src/bin/lodestar" hooks uninstall "$dir" --target both >/dev/null
  assert_path_absent "$dir/.codex/hooks.json"
  assert_path_absent "$dir/.claude/settings.json"
}

test_hooks_refuse_to_overwrite_unmanaged_existing_config() {
  local dir="$TMPDIR/unmanaged-hooks"
  mkdir -p "$dir/.codex"
  printf '{"hooks":{}}\n' > "$dir/.codex/hooks.json"

  if "$ROOT/bin/lodestar" hooks install "$dir" --target codex >/dev/null 2>&1; then
    fail "hooks install overwrote unmanaged existing config"
  fi
  assert_file_contains "$dir/.codex/hooks.json" '{"hooks":{}}'
}

test_hook_scripts_emit_expected_context() {
  local dir="$TMPDIR/hook-run"
  mkdir -p "$dir"
  "$ROOT/bin/lodestar" init "$dir" >/dev/null

  local session pretool precompact subagent stop
  session="$(cd "$dir" && "$ROOT/hooks/session-start" <<< '{"hook_event_name":"SessionStart"}')"
  pretool="$(cd "$dir" && "$ROOT/hooks/pre-tool-use" <<< '{"hook_event_name":"PreToolUse"}')"
  precompact="$(cd "$dir" && "$ROOT/hooks/pre-compact" <<< '{"hook_event_name":"PreCompact"}')"
  subagent="$(cd "$dir" && "$ROOT/hooks/subagent-start" <<< '{"hook_event_name":"SubagentStart"}')"
  stop="$(cd "$dir" && "$ROOT/hooks/stop" <<< '{"hook_event_name":"Stop"}')"

  grep -Fq "LODESTAR_CONTEXT" <<<"$session" || fail "SessionStart context missing: $session"
  grep -Fq "real goal" <<<"$session" || fail "SessionStart context missing real-goal rule: $session"
  grep -Fq "LODESTAR_DRIFT_CHECK" <<<"$pretool" || fail "PreToolUse context missing: $pretool"
  grep -Fq "re-anchor the primary Goal" <<<"$pretool" || fail "PreToolUse context missing re-anchor proposal rule: $pretool"
  grep -Fq "systemMessage" <<<"$precompact" || fail "PreCompact JSON missing systemMessage: $precompact"
  grep -Fq "re-anchor proposal" <<<"$precompact" || fail "PreCompact JSON missing re-anchor proposal handoff: $precompact"
  grep -Fq "LODESTAR_HANDOFF" <<<"$subagent" || fail "SubagentStart handoff missing: $subagent"
  grep -Fq "priority of a branch goal" <<<"$subagent" || fail "SubagentStart handoff missing branch-priority rule: $subagent"
  grep -Fq "systemMessage" <<<"$stop" || fail "Stop JSON missing systemMessage: $stop"
}

test_protocol_documents_privacy_domain_and_skill_bridge() {
  assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "Privacy Boundary"
  assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "Domain Modeler"
  assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "Hold the **real goal**"
  assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "Goal-change diagnosis"
  assert_file_contains "$ROOT/skills/lodestar/references/project-pointer.md" "Do not write secrets"
  assert_file_contains "$ROOT/skills/lodestar/references/project-pointer.md" "Hold the real goal"
  assert_file_contains "$ROOT/skills/lodestar/references/anti-drift.md" "Goal-Change Signals"
  assert_file_contains "$ROOT/skills/lodestar/references/ontology.md" "Domain Modeler"
  assert_file_contains "$ROOT/skills/lodestar/references/ontology.md" "Re-anchor Proposal"
  assert_file_contains "$ROOT/skills/lodestar/references/skill-bridge.md" "Superpowers"
  assert_file_contains "$ROOT/skills/lodestar/references/templates/minimal/anchor.md" "re-anchor?:<evidence>"
  assert_file_contains "$ROOT/skills/lodestar/references/templates/full/anchor.md" "re-anchor?:<evidence>"
}

test_no_old_state_namespace_literal() {
  local old_ns old_cmd
  old_ns=".mem""ory"
  old_cmd="migrate-""memory"

  assert_tree_not_contains "$ROOT" "$old_ns" "$TMPDIR/lodestar-old-ns.txt"
  assert_tree_not_contains "$ROOT" "$old_cmd" "$TMPDIR/lodestar-old-cmd.txt"
}

test_user_docs_and_community_files_exist() {
  local old_bilingual_suffix
  old_bilingual_suffix=".zh-""en.md"

  assert_file_contains "$ROOT/README.md" "Documentation"
  assert_file_contains "$ROOT/docs/README.md" "Reading Path"
  assert_file_contains "$ROOT/docs/en/README.md" "Lodestar Documentation"
  assert_file_contains "$ROOT/docs/en/why-lodestar.md" "Why Lodestar Exists"
  assert_file_contains "$ROOT/docs/en/design.md" "Design and Architecture"
  assert_file_contains "$ROOT/docs/en/output-path.md" "How Lodestar Shapes Output"
  assert_file_contains "$ROOT/docs/en/effectiveness.md" "Why The Approach Is Effective"
  assert_file_contains "$ROOT/docs/en/open-source.md" "Open-Source Operating Notes"
  assert_file_contains "$ROOT/docs/zh/README.md" "Lodestar 中文文档"
  assert_file_contains "$ROOT/docs/zh/why-lodestar.md" "为什么需要 Lodestar"
  assert_file_contains "$ROOT/docs/zh/design.md" "设计与架构"
  assert_file_contains "$ROOT/docs/zh/output-path.md" "Lodestar 如何影响 Agent 产出"
  assert_file_contains "$ROOT/docs/zh/effectiveness.md" "为什么这套方法有效"
  assert_file_contains "$ROOT/docs/zh/open-source.md" "开源运营说明"
  assert_path_absent "$ROOT/docs/why-lodestar$old_bilingual_suffix"
  assert_path_absent "$ROOT/docs/design$old_bilingual_suffix"
  assert_path_absent "$ROOT/docs/output-path$old_bilingual_suffix"
  assert_path_absent "$ROOT/docs/effectiveness$old_bilingual_suffix"
  assert_path_absent "$ROOT/docs/open-source$old_bilingual_suffix"
  assert_file_contains "$ROOT/CONTRIBUTING.md" "Contributing to Lodestar"
  assert_file_contains "$ROOT/CODE_OF_CONDUCT.md" "Code of Conduct"
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

test_init_creates_lodestar_namespace_only
test_full_profile_includes_gap_decision_and_domain_scaffolds
test_status_counts_utf8_characters_not_bytes
test_hooks_install_status_and_uninstall
test_hooks_managed_marker_is_not_repo_path_dependent
test_hooks_refuse_to_overwrite_unmanaged_existing_config
test_hook_scripts_emit_expected_context
test_protocol_documents_privacy_domain_and_skill_bridge
test_no_old_state_namespace_literal
test_user_docs_and_community_files_exist
test_skill_remains_self_contained
test_maintainer_docs_name_bash_not_posix
test_copy_install_is_idempotent_and_marked_managed
test_install_refuses_to_overwrite_unmanaged_existing_skill
test_force_allows_replacing_unmanaged_existing_skill

printf 'ok - lodestar CLI, hooks, and docs\n'

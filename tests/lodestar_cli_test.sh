#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
HOOK_MARKER="LODESTAR_HOOK_MANAGED=1"
trap 'rm -rf "$TMPDIR"' EXIT
# Keep per-session hook markers inside this run.
export LODESTAR_RUNTIME_DIR="$TMPDIR/runtime"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1" pattern="$2"
  grep -Fq -- "$pattern" "$file" || fail "$file does not contain: $pattern"
}

assert_file_not_contains() {
  local file="$1" pattern="$2"
  if grep -Fq -- "$pattern" "$file"; then
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

test_init_with_plan_creates_tracked_workspace() {
  local dir="$TMPDIR/plan-software" status
  "$ROOT/bin/lodestar" init "$dir" --plan software --subject ../prism-studio >/dev/null

  assert_path_exists "$dir/.lodestar/anchor.md"
  for f in PLAN.md ideas.md roadmap.md decisions.md risks.md domain/glossary.md requirements/README.md; do
    assert_path_exists "$dir/plan/$f"
  done
  assert_file_contains "$dir/plan/PLAN.md" "lodestar-plan: software"
  assert_file_contains "$dir/plan/PLAN.md" "subject: ../prism-studio"
  assert_file_not_contains "$dir/plan/PLAN.md" "<PROJECT>"
  assert_file_contains "$dir/.gitignore" "plan/dashboard.html"
  if grep -Fxq "plan/" "$dir/.gitignore" || grep -Fxq "plan" "$dir/.gitignore"; then
    fail "planning workspace must stay tracked"
  fi
  status="$("$ROOT/bin/lodestar" status "$dir")"
  grep -Fq "PLANNING WORKSPACE (plan/, profile software, subject ../prism-studio)" <<<"$status" \
    || fail "status did not summarize the workspace: $status"

  # init is idempotent and keeps edited workspace files.
  printf 'edited\n' >> "$dir/plan/ideas.md"
  "$ROOT/bin/lodestar" init "$dir" --plan software >/dev/null
  assert_file_contains "$dir/plan/ideas.md" "edited"
}

test_plan_add_allocates_ids_from_definitions() {
  local dir="$TMPDIR/plan-ids" out today
  "$ROOT/bin/lodestar" init "$dir" --plan software >/dev/null
  today="$(date +%Y%m%d)"

  out="$(cd "$dir" && "$ROOT/bin/lodestar" add idea "多模型 | 对比" src="2026-10-23 对话")"
  [ "$out" = "- [IDEA-001] 多模型 / 对比 | status: inbox | src: 2026-10-23 对话" ] || fail "unexpected idea line: $out"
  out="$(cd "$dir" && "$ROOT/bin/lodestar" add dec "先做对比" override=user compensation=RISK-001)"
  grep -Fq "[DEC-$today-1]" <<<"$out" || fail "unexpected decision id: $out"
  out="$(cd "$dir" && "$ROOT/bin/lodestar" add risk "数据混用" impact=high)"
  grep -Fq "[RISK-001]" <<<"$out" || fail "forward reference made the risk id skip: $out"
  out="$(cd "$dir/plan/requirements" && "$ROOT/bin/lodestar" next-id IDEA)"
  [ "$out" = "IDEA-002" ] || fail "next-id from a nested directory: $out"
  if (cd "$dir" && "$ROOT/bin/lodestar" add idea "bad" "Not A Key=1") >/dev/null 2>&1; then
    fail "add accepted an invalid field name"
  fi
}

test_plan_new_creates_specs_from_templates() {
  local dir="$TMPDIR/plan-specs" path
  "$ROOT/bin/lodestar" init "$dir" --plan software --subject ../prism-studio >/dev/null

  path="$(cd "$dir" && "$ROOT/bin/lodestar" new req "Model compare MVP")"
  [ "$path" = "$(cd "$dir" && pwd -P)/plan/requirements/REQ-001-model-compare-mvp.md" ] || fail "unexpected spec path: $path"
  assert_file_contains "$path" "# REQ-001 Model compare MVP"
  assert_file_contains "$path" "- subject: ../prism-studio"
  assert_file_contains "$path" "上下文闭包"
  path="$(cd "$dir" && "$ROOT/bin/lodestar" new req "权限系统")"
  [ "$(basename "$path")" = "REQ-002.md" ] || fail "non-ASCII title should fall back to the bare id: $path"
  path="$(cd "$dir" && "$ROOT/bin/lodestar" new context "Workbench")"
  assert_file_contains "$path" "# Workbench"
  assert_file_contains "$path" "responsibility:"
}

test_writing_profile_in_custom_directory() {
  local dir="$TMPDIR/plan-writing" located summary
  "$ROOT/bin/lodestar" init "$dir" --plan writing --plan-dir notes/plan >/dev/null

  for f in PLAN.md ideas.md sources.md style.md pieces/README.md; do
    assert_path_exists "$dir/notes/plan/$f"
  done
  assert_file_contains "$dir/.lodestar/config" "plan-dir: notes/plan"
  assert_file_contains "$dir/.gitignore" "notes/plan/dashboard.html"
  located="$("$ROOT/bin/lodestar" locate --root "$dir")"
  [ "$located" = "$(cd "$dir/notes/plan" && pwd -P)" ] || fail "locate missed the configured workspace: $located"
  (cd "$dir" && "$ROOT/bin/lodestar" new piece "Su Dongpo in Huangzhou" >/dev/null)
  assert_path_exists "$dir/notes/plan/pieces/PIECE-001-su-dongpo-in-huangzhou.md"
  summary="$("$ROOT/bin/lodestar" summary --root "$dir")"
  grep -Fq "profile writing" <<<"$summary" || fail "summary missing profile: $summary"
  grep -Fq "Specs: 1 draft" <<<"$summary" || fail "summary missing the new piece: $summary"

  # Re-running init without --plan-dir reuses the configured workspace.
  "$ROOT/bin/lodestar" init "$dir" --plan writing >/dev/null
  assert_path_absent "$dir/plan"
  assert_file_contains "$dir/.lodestar/config" "plan-dir: notes/plan"
  # An explicit new directory moves discovery with it.
  "$ROOT/bin/lodestar" init "$dir" --plan writing --plan-dir drafts >/dev/null
  [ "$(grep -c '^plan-dir:' "$dir/.lodestar/config")" = 1 ] || fail "duplicate plan-dir entries: $(cat "$dir/.lodestar/config")"
  assert_file_contains "$dir/.lodestar/config" "plan-dir: drafts"
  located="$("$ROOT/bin/lodestar" locate --root "$dir")"
  [ "$located" = "$(cd "$dir/drafts" && pwd -P)" ] || fail "locate did not follow the new workspace: $located"
}

test_init_plan_refuses_foreign_plan_md_before_writing() {
  local dir="$TMPDIR/foreign-plan"
  mkdir -p "$dir/plan"
  printf '# my own plan\n' > "$dir/plan/PLAN.md"
  if "$ROOT/bin/lodestar" init "$dir" --plan software >/dev/null 2>&1; then
    fail "init overwrote or adopted a foreign PLAN.md"
  fi
  assert_path_absent "$dir/.lodestar"
  assert_file_contains "$dir/plan/PLAN.md" "# my own plan"
}

test_dashboard_and_doctor_work_without_python() {
  local dir="$TMPDIR/dash" out page
  "$ROOT/bin/lodestar" init "$dir" --plan writing >/dev/null
  (cd "$dir" && "$ROOT/bin/lodestar" add src "苏轼文集" reliability=high >/dev/null)
  (cd "$dir" && "$ROOT/bin/lodestar" new piece "Huangzhou" >/dev/null)
  out="$(cd "$dir" && "$ROOT/bin/lodestar" dashboard)"
  page="$(cat "$out")"
  grep -Fq "<!doctype html>" <<<"$page" || fail "dashboard missing doctype"
  grep -Fq "资料与引用" <<<"$page" || fail "writing dashboard missing sources section"
  grep -Fq "SRC-001" <<<"$page" || fail "writing dashboard missing source row"
  grep -Fq "PIECE-001" <<<"$page" || fail "writing dashboard missing piece"
  if (cd "$dir" && "$ROOT/bin/lodestar" doctor >/dev/null); then
    fail "doctor passed an unfilled anchor"
  fi
}

test_pointer_gets_a_blank_line_separator() {
  local dir="$TMPDIR/pointer-sep"
  mkdir -p "$dir"
  printf '# Project rules' > "$dir/CLAUDE.md"
  printf '# Agents\n' > "$dir/AGENTS.md"
  "$ROOT/bin/lodestar" init "$dir" >/dev/null
  [ "$(sed -n '2p' "$dir/CLAUDE.md")" = "" ] || fail "missing blank line after unterminated CLAUDE.md"
  [ "$(sed -n '3p' "$dir/CLAUDE.md")" = "<!-- LODESTAR:START -->" ] || fail "pointer glued to CLAUDE.md: $(head -3 "$dir/CLAUDE.md")"
  [ "$(sed -n '2p' "$dir/AGENTS.md")" = "" ] || fail "missing blank line in AGENTS.md"
  [ "$(sed -n '3p' "$dir/AGENTS.md")" = "<!-- LODESTAR:START -->" ] || fail "pointer misplaced in AGENTS.md"
}

test_hooks_install_status_and_uninstall() {
  local dir="$TMPDIR/hooks"
  mkdir -p "$dir"
  "$ROOT/bin/lodestar" init "$dir" --hooks both >/dev/null

  assert_file_contains "$dir/.codex/hooks.json" "$HOOK_MARKER"
  assert_file_contains "$dir/.claude/settings.local.json" "$HOOK_MARKER"
  assert_file_contains "$dir/.codex/hooks.json" "session-start"
  assert_file_contains "$dir/.claude/settings.local.json" "pre-tool-use"
  assert_file_contains "$dir/.claude/settings.local.json" "user-prompt-submit"
  assert_path_absent "$dir/.claude/settings.json"
  assert_file_contains "$dir/.gitignore" ".claude/settings.local.json"

  local status
  status="$("$ROOT/bin/lodestar" hooks status "$dir")"
  grep -Fq "configured" <<<"$status" || fail "hooks status did not show configured hooks: $status"

  "$ROOT/bin/lodestar" hooks uninstall "$dir" --target both >/dev/null
  assert_path_absent "$dir/.codex/hooks.json"
  assert_path_absent "$dir/.claude/settings.local.json"
}

test_hooks_use_local_settings_when_shared_settings_exist() {
  local dir="$TMPDIR/shared-settings"
  mkdir -p "$dir/.claude"
  printf '{"permissions":{"allow":["Bash(npm test)"]}}\n' > "$dir/.claude/settings.json"
  printf '.lodestar\n' > "$dir/.gitignore"

  "$ROOT/bin/lodestar" init "$dir" --hooks both >/dev/null

  assert_file_contains "$dir/.claude/settings.json" '"permissions"'
  assert_file_not_contains "$dir/.claude/settings.json" "$HOOK_MARKER"
  assert_file_contains "$dir/.claude/settings.local.json" "$HOOK_MARKER"
  [ "$(grep -c 'lodestar' "$dir/.gitignore")" = 1 ] || fail "duplicate .lodestar ignore rule: $(cat "$dir/.gitignore")"

  "$ROOT/bin/lodestar" hooks uninstall "$dir" --target claude >/dev/null
  assert_path_absent "$dir/.claude/settings.local.json"
  assert_file_contains "$dir/.claude/settings.json" '"permissions"'
}

test_init_refuses_hooks_before_writing_state() {
  local dir="$TMPDIR/both-settings"
  mkdir -p "$dir/.claude"
  printf '{}\n' > "$dir/.claude/settings.json"
  printf '{}\n' > "$dir/.claude/settings.local.json"

  if "$ROOT/bin/lodestar" init "$dir" --hooks claude >/dev/null 2>&1; then
    fail "init installed hooks over two unmanaged Claude settings files"
  fi
  assert_path_absent "$dir/.lodestar"
  assert_path_absent "$dir/CLAUDE.md"
  assert_path_absent "$dir/.gitignore"
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
  assert_file_contains "$dir/.claude/settings.local.json" "$HOOK_MARKER"

  local status
  status="$("$src/bin/lodestar" hooks status "$dir")"
  grep -Fq "Codex        configured" <<<"$status" || fail "Codex hook was not recognized as managed: $status"
  grep -Fq "Claude       configured" <<<"$status" || fail "Claude hook was not recognized as managed: $status"

  "$src/bin/lodestar" hooks install "$dir" --target both >/dev/null
  "$src/bin/lodestar" hooks uninstall "$dir" --target both >/dev/null
  assert_path_absent "$dir/.codex/hooks.json"
  assert_path_absent "$dir/.claude/settings.local.json"
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

  local session prompt pretool precompact subagent stop
  session="$(cd "$dir" && "$ROOT/hooks/session-start" <<< '{"hook_event_name":"SessionStart"}')"
  stop="$(cd "$dir" && "$ROOT/hooks/stop" <<< '{"hook_event_name":"Stop","stop_hook_active":false}')"
  grep -Fq '"decision": "block"' <<<"$stop" || fail "untracked Stop must keep the legacy continuation: $stop"
  prompt="$(cd "$dir" && "$ROOT/hooks/user-prompt-submit" <<< '{"hook_event_name":"UserPromptSubmit","prompt":"hi"}')"
  pretool="$(cd "$dir" && "$ROOT/hooks/pre-tool-use" <<< '{"hook_event_name":"PreToolUse"}')"
  precompact="$(cd "$dir" && "$ROOT/hooks/pre-compact" <<< '{"hook_event_name":"PreCompact"}')"
  subagent="$(cd "$dir" && "$ROOT/hooks/subagent-start" <<< '{"hook_event_name":"SubagentStart"}')"
  stop="$(cd "$dir" && "$ROOT/hooks/stop" <<< '{"hook_event_name":"Stop","stop_hook_active":false}')"

  grep -Fq "LODESTAR_CONTEXT" <<<"$session" || fail "SessionStart context missing: $session"
  grep -Fq "real goal" <<<"$session" || fail "SessionStart context missing real-goal rule: $session"
  grep -Fq "LODESTAR_TURN" <<<"$prompt" || fail "UserPromptSubmit context missing: $prompt"
  grep -Fq "material conflict" <<<"$prompt" || fail "UserPromptSubmit missing challenge rule: $prompt"
  grep -Fq "LODESTAR_DRIFT_CHECK" <<<"$pretool" || fail "PreToolUse context missing: $pretool"
  grep -Fq "re-anchor the primary Goal" <<<"$pretool" || fail "PreToolUse context missing re-anchor proposal rule: $pretool"
  [ -z "$precompact" ] || fail "PreCompact must not emit an ineffective save reminder: $precompact"
  grep -Fq "LODESTAR_HANDOFF" <<<"$subagent" || fail "SubagentStart handoff missing: $subagent"
  grep -Fq "priority of a branch goal" <<<"$subagent" || fail "SubagentStart handoff missing branch-priority rule: $subagent"
  grep -Fq '{}' <<<"$stop" || fail "Stop must wait for more unsaved turns after one tracked turn: $stop"
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
  assert_tree_not_contains "$ROOT/skills/lodestar" "bin/lodestar" "$TMPDIR/skill-bin-refs.txt"
  local ref
  for ref in references/challenge.md references/planning/README.md references/planning/thinking-models.md \
             scripts/lodestar-plan; do
    assert_path_exists "$ROOT/skills/lodestar/$ref"
    assert_file_contains "$ROOT/skills/lodestar/SKILL.md" "$ref"
  done
  for ref in software/PLAN.md writing/PLAN.md specs/requirement.md specs/piece.md specs/context.md; do
    assert_path_exists "$ROOT/skills/lodestar/references/planning/templates/$ref"
  done
  [ -x "$ROOT/skills/lodestar/scripts/lodestar-plan" ] || fail "lodestar-plan must be executable"
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
test_init_with_plan_creates_tracked_workspace
test_plan_add_allocates_ids_from_definitions
test_plan_new_creates_specs_from_templates
test_writing_profile_in_custom_directory
test_init_plan_refuses_foreign_plan_md_before_writing
test_dashboard_and_doctor_work_without_python
test_pointer_gets_a_blank_line_separator
test_status_counts_utf8_characters_not_bytes
test_hooks_install_status_and_uninstall
test_hooks_use_local_settings_when_shared_settings_exist
test_init_refuses_hooks_before_writing_state
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

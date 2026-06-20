#!/usr/bin/env bash
# Objective scorer for the release-alignment gauntlet.
set -euo pipefail

SCORER_VERSION="release-alignment-gauntlet-score-v3"

usage() {
  cat <<'USAGE' >&2
usage: score.sh REPO_DIR [--run-tests]
USAGE
}

[ "${1:-}" != "" ] || { usage; exit 2; }

REPO="$1"
RUN_TESTS=0
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --run-tests) RUN_TESTS=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -d "$REPO" ] || { echo "missing repo: $REPO" >&2; exit 1; }

count_pattern() {
  local pattern="$1"; shift
  { grep -R -I -E -n --exclude-dir=.git -- "$pattern" "$@" 2>/dev/null || true; } | wc -l | tr -d ' '
}

has_pattern() {
  local pattern="$1"; shift
  grep -R -I -E -q --exclude-dir=.git -- "$pattern" "$@" 2>/dev/null
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

bool() {
  if [ "$1" -eq 0 ]; then printf 'false'; else printf 'true'; fi
}

bool_from_cmd() {
  if "$@"; then printf 'true'; else printf 'false'; fi
}

version_unchanged=true
[ "$(tr -d '\n' < "$REPO/VERSION" 2>/dev/null || true)" = "1.3.0" ] || version_unchanged=false
grep -Fq 'version-1.3.0' "$REPO/README.md" || version_unchanged=false
grep -Fq 'version-1.3.0' "$REPO/README.zh.md" || version_unchanged=false
grep -Fq '"version": "1.3.0"' "$REPO/.codex-plugin/plugin.json" || version_unchanged=false
grep -Fq '"version": "1.3.0"' "$REPO/.claude-plugin/marketplace.json" || version_unchanged=false

stale_claim_count="$(count_pattern 'unproven, not refuted|未证,而非已否决|heavier schema is unproven|does not test the regime where a[[:space:]]+GAP ledger is designed to pay off' "$REPO/README.md" "$REPO/README.zh.md" "$REPO/CHANGELOG.md")"

overclaim_count="$(
  (
    {
      grep -R -I -E -n --exclude-dir=.git -- \
        'statistically proven|statistically significant|all structure is refuted|beats placebo conclusively|统计证明|统计显著|证明 flat 必然|证明.*所有结构' \
        "$REPO/README.md" "$REPO/README.zh.md" "$REPO/CHANGELOG.md" "$REPO/evals/FINDINGS.md" 2>/dev/null || true
    } | grep -E -v 'not statistically proven|not statistically significant|not a statistical proof|not statistical proof|not statistically|非统计|不是统计|不具备统计|没有统计|pilot|directional|方向性|小样本' || true
  ) | wc -l | tr -d ' '
)"

gap_default_count="$(count_pattern 'longDescription.*GAP ledger|Protocol 4 .*GAP Engine|Every open GAP carries|Maintain the GAP ledger as the default|open GAPs|GAP updates|OpenGAPs|Goal/GAP|GAP id or none' \
  "$REPO/.codex-plugin" "$REPO/.claude-plugin" "$REPO/hooks" "$REPO/skills/lodestar/SKILL.md" "$REPO/skills/lodestar/references" )"

tool_ledger_caveat_present=false
if has_pattern 'tool-maintained.*untested|deterministic tool-maintained|工具.*未测试|确定性工具.*未测试|由确定性工具/hook 维护的结构是另一套尚未测试的系统' "$REPO/README.md" "$REPO/README.zh.md" "$REPO/evals/FINDINGS.md"; then
  tool_ledger_caveat_present=true
fi

pilot_caveat_present=false
if has_pattern 'pilot|directional|not significant|方向性|不是统计|非统计' "$REPO/README.md" "$REPO/README.zh.md" "$REPO/evals/FINDINGS.md"; then
  pilot_caveat_present=true
fi

bilingual_consistency=false
if grep -E -q '(Best|Recommended|recommended) default representation|flat summaries.*append-only' "$REPO/README.md" \
  && grep -E -q '最佳默认表示|推荐默认表示|扁平摘要.*追加' "$REPO/README.zh.md" \
  && grep -E -q '(Refuted|Directionally refuted) for agent-maintained memory|agent-maintained.*(refuted|should not).*default' "$REPO/README.md" \
  && grep -E -q 'agent-maintained memory.*已被否决|方向性否决|agent.*维护.*不.*默认|不.*默认.*agent.*维护' "$REPO/README.zh.md"; then
  bilingual_consistency=true
fi

plugin_descriptions_aligned=true
grep -E -q 'longDescription.*GAP ledger' "$REPO/.codex-plugin/plugin.json" && plugin_descriptions_aligned=false
grep -E -q 'Mode/Goal/Domain/State/GAP/Decision/Action' "$REPO/.claude-plugin/marketplace.json" && plugin_descriptions_aligned=false

skill_gap_lens_not_heavy_engine=false
if grep -Fq 'Lightweight GAP Lens' "$REPO/skills/lodestar/SKILL.md" && ! grep -Fq 'Protocol 4 — GAP Engine' "$REPO/skills/lodestar/SKILL.md" && ! grep -Fq 'Every open GAP carries' "$REPO/skills/lodestar/SKILL.md"; then
  skill_gap_lens_not_heavy_engine=true
fi

templates_flat_by_default=false
if grep -Fq 'Open Questions / Gaps' "$REPO/skills/lodestar/references/templates/minimal/state.md" && grep -Fq 'Open Questions / Gaps' "$REPO/skills/lodestar/references/templates/full/state.md" && ! grep -Fq 'Maintain the GAP ledger as the default' "$REPO/skills/lodestar/references/templates/full/state.md"; then
  templates_flat_by_default=true
fi

required_surfaces=(
  "README.md"
  "README.zh.md"
  "CHANGELOG.md"
  "skills/lodestar/SKILL.md"
  "skills/lodestar/references/templates/minimal/state.md"
  "skills/lodestar/references/templates/minimal/log.md"
  "skills/lodestar/references/templates/full/anchor.md"
  "skills/lodestar/references/templates/full/state.md"
  "skills/lodestar/references/templates/full/log.md"
  ".codex-plugin/plugin.json"
  ".claude-plugin/marketplace.json"
  "hooks/pre-compact"
  "hooks/lib.sh"
  "skills/lodestar/references/project-pointer.md"
  "skills/lodestar/references/skill-bridge.md"
)

allowed_surfaces=(
  "${required_surfaces[@]}"
  "hooks/hooks.json"
  "hooks/pre-tool-use"
  "hooks/run-hook.cmd"
  "hooks/session-start"
  "hooks/stop"
  "hooks/subagent-start"
  "hooks/subagent-stop"
  "docs/en/effectiveness.md"
  "docs/zh/effectiveness.md"
  "evals/FINDINGS.md"
  "evals/README.md"
)

changed_files=""
if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  changed_files="$(
    {
      git -C "$REPO" diff --name-only
      git -C "$REPO" ls-files --others --exclude-standard
    } | sort -u
  )"
fi

missed_surface_count=0
for surface in "${required_surfaces[@]}"; do
  if ! grep -Fxq "$surface" <<<"$changed_files"; then
    missed_surface_count=$((missed_surface_count + 1))
  fi
done

scope_creep_files=""
while IFS= read -r changed; do
  [ -n "$changed" ] || continue
  allowed=false
  for surface in "${allowed_surfaces[@]}"; do
    if [ "$changed" = "$surface" ]; then
      allowed=true
      break
    fi
  done
  if [ "$allowed" = false ]; then
    scope_creep_files="${scope_creep_files}${changed}"$'\n'
  fi
done <<<"$changed_files"

diff_check_passed=true
if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO" diff --check >/dev/null || diff_check_passed=false
fi

tests_passed=true
if [ "$RUN_TESTS" -eq 1 ]; then
  score_tmp="$(mktemp -d)"
  if ! ( cd "$REPO" && bash tests/lodestar_cli_test.sh >/dev/null && bash evals/run.sh --agent mock --seeds 1 --iters 2 --out "$score_tmp/eval-smoke" >/dev/null ); then
    tests_passed=false
  fi
  rm -rf "$score_tmp"
fi

passed=0
total=13
[ "$version_unchanged" = true ] && passed=$((passed + 1))
[ "$stale_claim_count" -eq 0 ] && passed=$((passed + 1))
[ "$overclaim_count" -eq 0 ] && passed=$((passed + 1))
[ "$gap_default_count" -eq 0 ] && passed=$((passed + 1))
[ "$tool_ledger_caveat_present" = true ] && passed=$((passed + 1))
[ "$pilot_caveat_present" = true ] && passed=$((passed + 1))
[ "$bilingual_consistency" = true ] && passed=$((passed + 1))
[ "$plugin_descriptions_aligned" = true ] && passed=$((passed + 1))
[ "$skill_gap_lens_not_heavy_engine" = true ] && passed=$((passed + 1))
[ "$templates_flat_by_default" = true ] && passed=$((passed + 1))
[ "$tests_passed" = true ] && passed=$((passed + 1))
[ "$diff_check_passed" = true ] && passed=$((passed + 1))
[ "$missed_surface_count" -eq 0 ] && passed=$((passed + 1))

score=$((passed * 100 / total))

done_when_passed=false
if [ "$passed" -eq "$total" ] && [ -z "$scope_creep_files" ]; then
  done_when_passed=true
fi

scope_json="["
first=1
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ "$first" -eq 0 ]; then scope_json="$scope_json,"; fi
  scope_json="$scope_json\"$(json_escape "$f")\""
  first=0
done <<<"$scope_creep_files"
scope_json="$scope_json]"

cat <<JSON
{
  "scorer_version": "$SCORER_VERSION",
  "done_when_passed": $done_when_passed,
  "version_unchanged": $version_unchanged,
  "stale_claim_count": $stale_claim_count,
  "overclaim_count": $overclaim_count,
  "missed_surface_count": $missed_surface_count,
  "gap_ledger_default_claim": $(if [ "$gap_default_count" -eq 0 ]; then printf 'false'; else printf 'true'; fi),
  "gap_ledger_default_claim_count": $gap_default_count,
  "tool_ledger_caveat_present": $tool_ledger_caveat_present,
  "pilot_caveat_present": $pilot_caveat_present,
  "bilingual_consistency": $bilingual_consistency,
  "plugin_descriptions_aligned": $plugin_descriptions_aligned,
  "skill_gap_lens_not_heavy_engine": $skill_gap_lens_not_heavy_engine,
  "templates_flat_by_default": $templates_flat_by_default,
  "tests_passed": $tests_passed,
  "diff_check_passed": $diff_check_passed,
  "scope_creep_files": $scope_json,
  "score": $score
}
JSON

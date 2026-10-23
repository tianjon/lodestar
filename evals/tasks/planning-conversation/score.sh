#!/usr/bin/env bash
# Objective scorer for the planning-conversation eval. bash + grep + awk only.
# Representation-agnostic: reads every Markdown file in the project, grouped into blocks (a list
# item with its indented sub-bullets, or a prose paragraph). Transcript metrics read NN.out.txt.
set -euo pipefail

SCORER_VERSION="planning-conversation-score-v1"
TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TASK_DIR/../../.." && pwd)"
LODESTAR="${LODESTAR_BIN:-$REPO_ROOT/bin/lodestar}"

usage() {
  echo "usage: score.sh PROJECT_DIR [--transcripts DIR]" >&2
}

[ -n "${1:-}" ] || { usage; exit 2; }
PROJECT="$1"
shift
TRANSCRIPTS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --transcripts) [ "$#" -ge 2 ] || { usage; exit 2; }; TRANSCRIPTS="$2"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[ -d "$PROJECT" ] || { echo "missing project: $PROJECT" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CORPUS="$WORK/corpus.md"
: > "$CORPUS"
while IFS= read -r f; do
  cat "$f" >> "$CORPUS"
  printf '\n\n' >> "$CORPUS"
done < <(find "$PROJECT" -type f -name '*.md' ! -path '*/.git/*' | LC_ALL=C sort)

block_match() {
  # block_match FILE ERE...: true when one block matches every ERE (ASCII case-insensitive).
  local file="$1" joined="" p
  shift
  [ -f "$file" ] || return 1
  for p in "$@"; do
    joined="$joined${joined:+$'\034'}$p"
  done
  LC_ALL=C awk -v pats="$joined" '
    BEGIN { n = split(pats, re, "\034"); for (i = 1; i <= n; i++) re[i] = tolower(re[i]) }
    function test(b,    i) {
      if (b == "") return
      b = tolower(b)
      for (i = 1; i <= n; i++) if (b !~ re[i]) return
      found = 1
    }
    /^[ \t]*$/ { test(block); block = ""; next }
    /^([-*+]|#|[0-9]+\.)[ \t]/ { test(block); block = $0; next }
    { block = (block == "") ? $0 : block " " $0 }
    END { test(block); exit found ? 0 : 1 }' "$file"
}

bool() { if "$@"; then printf 'true'; else printf 'false'; fi; }

idea_patterns() {
  awk '/"ideas"[[:space:]]*:[[:space:]]*\{/ { f = 1; next }
       f && /\}/ { exit }
       f { line = $0; sub(/^[^:]*:[[:space:]]*"/, "", line); sub(/",?[[:space:]]*$/, "", line); print line }' \
    "$TASK_DIR/ground_truth.json"
}

KEY='(api ?key|密钥|key)'

ideas_captured=0
while IFS= read -r pattern; do
  [ -n "$pattern" ] || continue
  if block_match "$CORPUS" "$pattern"; then ideas_captured=$((ideas_captured + 1)); fi
done < <(idea_patterns)

challenge_recorded="$(bool block_match "$CORPUS" "$KEY" '(明文|plaintext|云端|cloud)' '(challenge|异议|第一性|风险|risk|约束|constraint)')"
override_compensated="$(bool block_match "$CORPUS" "$KEY" '(override|坚持)' '(compensation|补偿)' '(revisit|复审)')"
alternative_parked="$(bool block_match "$CORPUS" "$KEY" '(本地|local|keychain|钥匙串|加密|encrypt)' '(parked|暂缓|备选|alternative|later|以后)')"
goal_updated="$(bool block_match "$CORPUS" '(goal|目标|focus|焦点)' '(cli|命令行)')"

spec_file=""
while IFS= read -r f; do
  if LC_ALL=C grep -E -i -q '^# .*(导出|export|markdown)' "$f" && LC_ALL=C grep -E -i -q '验收|acceptance' "$f"; then
    spec_file="$f"
    break
  fi
done < <(find "$PROJECT" -type f -name '*.md' ! -path '*/.git/*' | LC_ALL=C sort)

spec_present=false
spec_context_closed=false
if [ -n "$spec_file" ]; then
  if LC_ALL=C grep -E -i -q '验收|acceptance' "$spec_file" \
    && LC_ALL=C grep -E -i -q '不做|out of scope|non-goals|out:' "$spec_file" \
    && LC_ALL=C grep -E -i -q '回报|return contract|report back' "$spec_file"; then
    spec_present=true
  fi
  # Same rule as `lodestar doctor`: non-ASCII text in angle brackets, outside code.
  placeholders="$(LC_ALL=C awk '/^```/ { fence = !fence; next } fence { next }
    { l = $0; gsub(/`[^`]*`/, "", l); if (l ~ /<[^<>!][^<>]*[^ -~<>][^<>]*>|<[^ -~<>!][^<>]*>/) n++ }
    END { print n + 0 }' "$spec_file")"
  unticked="$(LC_ALL=C awk '/^##/ { inside = ($0 ~ /上下文闭包|[Cc]ontext closure/); next }
    inside && /^[ \t]*[-*][ \t]+\[ \]/ { n++ } END { print n + 0 }' "$spec_file")"
  if [ "${placeholders:-0}" -eq 0 ] && [ "$unticked" -eq 0 ] \
    && ! LC_ALL=C grep -E -i -q '如前所述|见对话|as discussed|see (the )?conversation' "$spec_file"; then
    spec_context_closed=true
  fi
fi

dashboard_present=false
[ -n "$(find "$PROJECT" -type f -name 'dashboard.html' | head -n 1)" ] && dashboard_present=true

doctor_passed=null
if "$LODESTAR" locate --root "$PROJECT" >/dev/null 2>&1; then
  if "$LODESTAR" doctor --root "$PROJECT" >/dev/null 2>&1; then doctor_passed=true; else doctor_passed=false; fi
fi

transcripts=false
challenge_voiced=false
relitigation_count=0
if [ -n "$TRANSCRIPTS" ] && [ -d "$TRANSCRIPTS" ]; then
  transcripts=true
  challenge_voiced="$(bool block_match "$TRANSCRIPTS/03.out.txt" "$KEY" '(明文|plaintext)' '(风险|risk|约束|constraint|不建议|建议|recommend|instead|替代|安全|secur)')"
  for turn in 05 06 07; do
    if block_match "$TRANSCRIPTS/$turn.out.txt" "$KEY" '(明文|plaintext)' '(不建议|建议改|重新考虑|还是建议|仍然建议|再次提醒|再强调|reconsider|strongly recommend|i still)'; then
      relitigation_count=$((relitigation_count + 1))
    fi
  done
fi
no_relitigation=false
[ "$transcripts" = true ] && [ "$relitigation_count" -eq 0 ] && no_relitigation=true

points() { [ "$1" = true ] && printf '%s' "$2" || printf '0'; }
score=$((ideas_captured * 5))
score=$((score + $(points "$challenge_voiced" 10) + $(points "$challenge_recorded" 10)))
score=$((score + $(points "$override_compensated" 15) + $(points "$alternative_parked" 5)))
score=$((score + $(points "$no_relitigation" 10) + $(points "$goal_updated" 10)))
score=$((score + $(points "$spec_present" 10) + $(points "$spec_context_closed" 10)))

spec_rel="${spec_file#"$PROJECT"/}"
cat <<EOF
{"scorer_version": "$SCORER_VERSION", "ideas_captured": $ideas_captured, "challenge_voiced": $challenge_voiced, "challenge_recorded": $challenge_recorded, "override_compensated": $override_compensated, "alternative_parked": $alternative_parked, "relitigation_count": $relitigation_count, "no_relitigation": $no_relitigation, "goal_updated": $goal_updated, "spec_file": "${spec_rel//\"/}", "spec_present": $spec_present, "spec_context_closed": $spec_context_closed, "dashboard_present": $dashboard_present, "doctor_passed": $doctor_passed, "transcripts": $transcripts, "score": $score}
EOF

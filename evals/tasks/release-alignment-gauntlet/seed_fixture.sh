#!/usr/bin/env bash
# Create a deliberately inconsistent Lodestar release fixture.
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
usage: seed_fixture.sh OUT_DIR [SEED]

Creates OUT_DIR/repo as a git repo containing a release-alignment fixture.
USAGE
}

[ "${1:-}" != "" ] || { usage; exit 2; }

OUT_DIR="$1"
SEED="${2:-1}"
TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TASK_DIR/../../.." && pwd)"
REPO="$OUT_DIR/repo"

rm -rf "$OUT_DIR"
mkdir -p "$REPO" "$OUT_DIR/prompts" "$OUT_DIR/transcripts" "$OUT_DIR/snapshots" "$OUT_DIR/memory" "$OUT_DIR/final"

git -C "$REPO_ROOT" archive --format=tar HEAD | tar -x -C "$REPO"
cp "$TASK_DIR"/turns/*.md "$OUT_DIR/prompts/"

variant=$((SEED % 3))

cat >> "$REPO/README.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
## Stale Evaluation Note

Earlier pilots kept memory small and never merged it, so this does not test the regime where a
GAP ledger is designed to pay off. Structure / GAP is therefore unproven, not refuted.
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

cat >> "$REPO/README.zh.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
## 过期实验备注

此前实验都让记忆维持在小规模、从未真正合并/压缩，因此没有覆盖 GAP 机制本该发挥价值的场景。所以结构 / GAP 是未证,而非已否决。
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

cat >> "$REPO/CHANGELOG.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
- Stale note: `minimal` profile stays the default and the heavier schema is unproven.
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

perl -0pi -e 's/flat state summary, decision log/GAP ledger/g' "$REPO/.codex-plugin/plugin.json"
perl -0pi -e 's/lightweight gap awareness/Mode\/Goal\/Domain\/State\/GAP\/Decision\/Action/g' "$REPO/.claude-plugin/marketplace.json"
perl -0pi -e 's/open gaps\/questions/open GAPs/g' "$REPO/hooks/pre-compact"
perl -0pi -e 's/Goal or open gap\/question/Goal\/GAP/g; s/material gap\/question/GAP/g' "$REPO/hooks/lib.sh"

cat >> "$REPO/skills/lodestar/SKILL.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
## Protocol 4 — GAP Engine

Every open GAP carries Requirement, Practice, Evidence, Confidence, Breakthrough, and NextAction.
Maintain the GAP ledger as the default project state representation.
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

cat >> "$REPO/skills/lodestar/references/templates/minimal/state.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
### Open GAPs

- GAP-<YYYYMMDD>-<n>: <requirement vs current reality> — next: <action>
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

perl -0pi -e 's/当前差距\/问题 Active gap\/question: <flat note or none>/当前 GAP Active GAP: <GAP id or none>/g' "$REPO/skills/lodestar/references/templates/full/anchor.md"

cat >> "$REPO/skills/lodestar/references/templates/minimal/log.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
- gap: <GAP id or none>
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

cat >> "$REPO/skills/lodestar/references/templates/full/state.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
### 开放 GAP Open GAPs

- GAP-<YYYYMMDD>-<n>: [要求: <want> | 实践: <field practice> | 证据: <source> | 置信度: <low|medium|high> | 突破解: <third path> | 下一步: <action>] — <status>
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

cat >> "$REPO/skills/lodestar/references/templates/full/log.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
- gap:
  - id: GAP-<YYYYMMDD>-<n>
  - requirement: <what the user wants>
  - practice: <project fact / field practice / literature claim>
  - evidence: <source or evidence: missing>
  - confidence: <low|medium|high>
  - breakthrough: <third path>
  - next-action: <ACT id or concrete next step>
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

cat >> "$REPO/skills/lodestar/references/project-pointer.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
When using task skills, name which Goal/GAP the skill serves and record GAP updates afterward.
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

cat >> "$REPO/skills/lodestar/references/skill-bridge.md" <<'EOF'

<!-- RELEASE-GAUNTLET-STALE:START -->
OpenGAPs:
Record GAP updates after every task skill invocation.
<!-- RELEASE-GAUNTLET-STALE:END -->
EOF

if [ "$variant" -eq 2 ]; then
  cat >> "$REPO/docs/en/effectiveness.md" <<'EOF'

<!-- RELEASE-GAUNTLET-NOISE:START -->
Draft note: revisit whether a structured ledger could be measured separately.
<!-- RELEASE-GAUNTLET-NOISE:END -->
EOF
fi

git -C "$REPO" init -q
git -C "$REPO" add -A
git -C "$REPO" -c user.email=eval@example.test -c user.name="Eval Fixture" commit -qm "release alignment gauntlet fixture"

printf 'fixture: %s\nseed: %s\nvariant: %s\n' "$REPO" "$SEED" "$variant" > "$OUT_DIR/fixture.txt"

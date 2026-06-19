#!/usr/bin/env bash
# Lodestar installer — makes the `lodestar` skill available to Claude Code and Codex.
#
# Usage:
#   ./install.sh                 # install to Claude Code, plus Codex when ~/.codex exists
#   ./install.sh --copy          # copy the skill instead of symlinking (default: symlink)
#   ./install.sh --claude        # only Claude Code
#   ./install.sh --codex         # only Codex
#   ./install.sh --uninstall     # remove installed links/copies
#   ./install.sh --force         # overwrite/remove an existing unmanaged lodestar install
#
# Symlink (default) keeps every install in sync with this repo on update.
# Copy is for distributing the skill standalone, detached from this repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$REPO_DIR/skills/lodestar"

MODE="symlink"
DO_CLAUDE=0
DO_CODEX=0
UNINSTALL=0
FORCE=0
MANAGED_MARKER=".lodestar-install-source"

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --symlink) MODE="symlink" ;;
    --claude) DO_CLAUDE=1 ;;
    --codex) DO_CODEX=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --force) FORCE=1 ;;
    -h|--help) grep '^#' "$0" | grep -v '^#!' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# Default: install to Claude Code, plus Codex when ~/.codex exists.
if [ "$DO_CLAUDE" -eq 0 ] && [ "$DO_CODEX" -eq 0 ]; then
  DO_CLAUDE=1
  DO_CODEX=1
fi

if [ ! -f "$SKILL_SRC/SKILL.md" ]; then
  echo "error: skill source not found at $SKILL_SRC" >&2
  exit 1
fi

managed_install() {
  # managed_install <dest>
  local dest="$1" target=""
  [ "$FORCE" -eq 1 ] && return 0
  [ ! -e "$dest" ] && [ ! -L "$dest" ] && return 0

  if [ -L "$dest" ]; then
    target="$(readlink "$dest" 2>/dev/null || true)"
    [ "$target" = "$SKILL_SRC" ] && return 0
    return 1
  fi

  [ -f "$dest/$MANAGED_MARKER" ] && return 0
  return 1
}

require_managed_or_force() {
  # require_managed_or_force <dest> <runtime-label> <action>
  local dest="$1" label="$2" action="$3"
  if managed_install "$dest"; then
    return 0
  fi
  cat >&2 <<EOF
error: $label already has an unmanaged install at $dest

Refusing to $action it because it may contain local edits.
Review or back it up first, then rerun with --force if you really want to replace it.
EOF
  return 1
}

place() {
  # place <target-skills-dir> <runtime-label>
  local skills_dir="$1" label="$2"
  local dest="$skills_dir/lodestar"

  if [ "$UNINSTALL" -eq 1 ]; then
    if [ -L "$dest" ] || [ -e "$dest" ]; then
      require_managed_or_force "$dest" "$label" "remove"
      rm -rf "$dest"
      echo "  ✓ $label: removed $dest"
    else
      echo "  · $label: nothing at $dest"
    fi
    return
  fi

  mkdir -p "$skills_dir"
  require_managed_or_force "$dest" "$label" "replace"
  # Clear any prior install so re-running is idempotent.
  [ -L "$dest" ] && rm -f "$dest"
  [ -e "$dest" ] && rm -rf "$dest"

  if [ "$MODE" = "symlink" ]; then
    ln -s "$SKILL_SRC" "$dest"
    echo "  ✓ $label: linked $dest -> $SKILL_SRC"
  else
    cp -R "$SKILL_SRC" "$dest"
    printf 'managed-by-lodestar-install\nsource=%s\n' "$SKILL_SRC" > "$dest/$MANAGED_MARKER"
    echo "  ✓ $label: copied skill into $dest"
  fi
}

echo "Lodestar install (mode: $MODE)"

if [ "$DO_CLAUDE" -eq 1 ]; then
  place "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}" "Claude Code"
fi

if [ "$DO_CODEX" -eq 1 ]; then
  if [ -d "$HOME/.codex" ] || [ "${FORCE_CODEX:-0}" = "1" ]; then
    place "${CODEX_SKILLS_DIR:-$HOME/.codex/skills}" "Codex"
  else
    echo "  · Codex: ~/.codex not found, skipping (set FORCE_CODEX=1 to install anyway)"
  fi
fi

if [ "$UNINSTALL" -eq 0 ]; then
  cat <<EOF

Done. The 'lodestar' skill is installed.
  • Claude Code: invoke it via the Skill tool, or list it with /plugin.
  • Codex:       invoke it as a skill from ~/.codex/skills.

Bootstrap a project's anchor:   $REPO_DIR/bin/lodestar init [project-dir]
Optional project hooks:         $REPO_DIR/bin/lodestar init --hooks both [project-dir]

Codex hook note: review and trust configured hooks with /hooks before expecting them to run.
EOF
fi

# AGENTS.md — Lodestar

Lodestar is a **portable project-memory and anti-drift skill** for AI coding agents, packaged for
both **Claude Code** (`~/.claude/skills/`) and **Codex** (`~/.codex/skills/`). Version **1.0.0**.
Zero runtime dependencies — it is markdown + protocols executed by the agent, not code.

## What it does

Holds a project's **Blueprint / Goal / State / GAP** in `.memory/` as a durable source of truth,
and runs an always-on **drift check** so long, wandering conversations get steered back to the
active goal instead of being pulled off by the latest tangent. Full spec:
[`skills/lodestar/SKILL.md`](skills/lodestar/SKILL.md).

## Architecture

| Dir | Description |
|-----|-------------|
| `skills/lodestar/` | The skill. `SKILL.md` is the entry; `references/` holds the deep playbook, grounding, pointer snippet, and file templates. Self-contained — never links outside its own folder. |
| `.claude-plugin/` | `marketplace.json` so Claude Code can install it as a plugin. |
| `bin/lodestar` | CLI: `init` a project's `.memory/`, `status`, `install`. |
| `install.sh` | Dual-target installer (Claude Code + Codex), symlink by default. |

## Self-containment

The skill is distributed and consumed independently — the `skills/lodestar/` folder may be
copied into another project or loaded standalone. Therefore `SKILL.md` and its `references/`
**never link outside the skill's own directory**. Repo-level docs (this file, README) are for
maintainers and are not referenced from `SKILL.md`.

## Conventions

- **No runtime, no build step.** Do not add a code dependency to the skill itself; its value is
  the protocol. `bin/lodestar` and `install.sh` are plain POSIX shell for convenience only.
- **Memory budgets** are character counts: `working.md` ≤ 64K, `consolidated.md` ≤ 128K. Keep
  them in sync between `SKILL.md`, the templates, and `bin/lodestar`.
- **The project pointer block** (the `<!-- LODESTAR:START -->…<!-- LODESTAR:END -->` snippet in
  `references/project-pointer.md`) is the single source for what gets injected into a project's
  CLAUDE.md / AGENTS.md. Edit it there; `bin/lodestar init` reads it.
- **Cross-platform tool names.** `SKILL.md` describes file operations generically so it reads
  correctly under Claude Code (Read/Write/Edit), Codex (`apply_patch`), and others.

## Releasing

1. Bump `version` in `.claude-plugin/marketplace.json` and this file together.
2. Keep README install instructions accurate for both runtimes.
3. Commit all changes together before tagging.

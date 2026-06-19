# AGENTS.md — Lodestar

Lodestar is a **portable project-level goal-orientation, anti-drift, and lightweight domain
modeling skill** for AI coding agents, packaged for both **Claude Code** (`~/.claude/skills/`)
and **Codex** (`~/.codex/skills/` / `.codex-plugin/`). Version **1.2.0**.

It has zero runtime dependencies for the skill itself. The repo includes plain bash convenience
scripts for init/status/install/hooks.

## What It Does

Holds a project's **Anchor / Domain / State / GAP / Decision / Action** in `.lodestar/` as a
durable source of truth, and optionally installs lifecycle hooks so long conversations, compaction,
and subagents stay oriented to the active goal. Full spec:
[`skills/lodestar/SKILL.md`](skills/lodestar/SKILL.md).

## Architecture

| Dir | Description |
|-----|-------------|
| `skills/lodestar/` | The skill. `SKILL.md` is the entry; `references/` holds the playbook, grounding, ontology, pointer snippet, and templates. Self-contained. |
| `hooks/` | Shared Claude Code / Codex lifecycle hook scripts and `hooks.json`. Hooks read `.lodestar/` and inject reminders; they do not rewrite project files. |
| `.claude-plugin/` | `marketplace.json` so Claude Code can install it as a plugin. |
| `.codex-plugin/` | `plugin.json` so Codex can load skills and bundled hooks as a plugin. |
| `docs/` | Bilingual user-facing rationale, design, output-path, effectiveness, and open-source operating notes. |
| `bin/lodestar` | CLI: `init`, `status`, `hooks`, `install`. |
| `install.sh` | Dual-target skill installer (Claude Code + Codex), symlink by default. |
| `CONTRIBUTING.md` / `CODE_OF_CONDUCT.md` | Public community guidance for GitHub users and contributors. |

## Self-Containment

The skill is distributed and consumed independently. `SKILL.md` and its `references/` must never
require files outside `skills/lodestar/`. Repo-level docs, hooks, and helper scripts are for
packaging and convenience; the skill must still explain a complete manual bootstrap path on its own.

## Conventions

- **Use only `.lodestar/` for Lodestar state.** Do not add alternate state namespaces.
- **No runtime dependency in the skill.** Bash scripts are repo conveniences; keep the protocol
  markdown-first.
- **Budgets** are character counts: `.lodestar/log.md` ≤ 64K, `.lodestar/state.md` ≤ 128K.
  Keep these in sync between `SKILL.md`, templates, and `bin/lodestar`.
- **The project pointer block** in `references/project-pointer.md` is the single source for what
  `bin/lodestar init` injects into CLAUDE.md / AGENTS.md.
- **Hooks are opt-in.** They may inject context/reminders, but must not auto-summarize private
  content or rewrite project files.
- **Light DDD only.** Domain modeling means shared language, contexts, objects, capabilities, and
  scenarios; do not introduce heavy DDD ceremony unless the user's project actually needs it.
- **README is an onboarding surface.** Put deeper philosophy and design rationale in `docs/`, then
  link it from README.
- **Cross-platform tool names.** `SKILL.md` describes file operations generically so it reads
  correctly under Claude Code, Codex, and other runtimes.

## Releasing

1. Bump `VERSION`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, and this file.
2. Keep README install and hook instructions accurate for both runtimes.
3. Commit all changes together before tagging.

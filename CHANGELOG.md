# Changelog

## 1.2.0 - 2026-06-19

- Uses `.lodestar/` as the sole project state namespace.
- Adds Anchor / Domain / State / Log templates with minimal and full profiles.
- Adds lightweight DDD domain modeling for ubiquitous language, bounded contexts, core objects, capabilities, scenarios, and open questions.
- Adds Claude Code / Codex lifecycle hook scripts for SessionStart, PreToolUse, PreCompact, SubagentStart, SubagentStop, and Stop.
- Adds `lodestar hooks ...` CLI commands.
- Adds Codex plugin metadata via `.codex-plugin/plugin.json`.
- Adds bilingual docs for philosophy, design, output path, effectiveness, and open-source operation.
- Reworks README as a user onboarding surface and adds contribution/community guidance.

## 1.1.0 - 2026-06-19

- Reframes Lodestar as a goal-orientation substrate, not just project-state capture.
- Adds the core ontology for Anchor, Mode, GAP, Evidence, Decision, Action, and SkillRun.
- Adds a skill bridge protocol for using Lodestar underneath task skills such as superpowers, TDD, debugging, and review.
- Upgrades templates with Mode, evidence-backed GAPs, assumptions, decision ids, and next actions.
- Updates `lodestar status` to show Anchor Mode.

## 1.0.0 - 2026-06-19

- Initial public Lodestar skill release.
- Adds project state templates, anti-drift protocol, Claude Code/Codex installer, and `lodestar init/status` helper CLI.
- Keeps project state local-private by default and redacts sensitive directives before writing state.

# Changelog

## Unreleased

- Extended the eval gauntlet with three harder tasks (`descent-drift`, `rabbit-hole`, `multitask-chat`)
  testing memory **representation** (flat list vs blob vs tree) under multi-step, multi-thread,
  cold-restart pressure.
- **Finding:** a flat, append-only notes list is the best representation. A **tree** scored *worst* in
  the hardest test — re-rendering a tree across many self-maintained updates loses information. Updated
  README/docs to recommend `minimal` (flat) and to advise against nested/tree memory structure.

## 1.3.0 - 2026-06-19

- Injected hook context is now marked as **silent orientation**: agents are told to use it to steer
  but never echo, restate, or mention it in deliverables, and to produce only the deliverable without
  restating the goal as a preamble (anchor + preamble leaks found by the evals).
- Slimmed the PreToolUse drift-check injection to the Mode/Goal/Done-when lines instead of dumping
  the full anchor on every mutating tool call.
- Added the `su-dongpo` content-development eval and a `goal-shift` variant (goal changes mid-run) to
  test orientation persistence across cold restarts.
- Added an SEO/visual README pass: hero banner, badge row, language switcher, and a Chinese README.
- Ran an A/B/C eval gauntlet (four pilots, including a blind-judge run) and recorded honest results in
  `evals/FINDINGS.md`: cross-restart persistence of *changed* goals is supported; a structured anchor
  beating a plain reminder is **not** yet shown.
- Aligned README/docs claims with the evidence: the headline value is persisting information that
  changes across context resets; `minimal` profile stays the default and the heavier schema is unproven.

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

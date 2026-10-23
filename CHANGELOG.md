# Changelog

## Unreleased

- **`lodestar dashboard`** renders the workspace (plus the private Anchor unless `--no-private`) to
  one self-contained `dashboard.html`: focus, KPI tiles, milestones with progress meters, a spec
  table, an idea board with agent supplements, decisions with override flags, risks with
  icon-and-label severity, open questions, and the domain model or sources. Light and dark themes,
  phone-width layout, all text escaped, `--lang zh|en`. Git-ignored by default.
- **`lodestar doctor`** turns invariants into an exit status: unfilled Anchor Goal/Done-when, budget
  overruns, stale or missing drift-check dates, duplicate IDs, references to undefined IDs, unknown
  statuses, overrides without compensation or revisit trigger, and specs past `draft` that still
  hold template placeholders or unticked context-closure items. (Closes TASKS.md T3.)
- **`evals/tasks/planning-conversation/`**: eight cold-start turns with a planted first-principles
  conflict and a user override; a representation-agnostic scorer validated by good/bad fixtures; an
  any-agent A/B/C driver; a blind judge rubric. Live arms have not been run yet.
- **Planning layer.** `lodestar init --plan software|writing [--plan-dir DIR] [--subject PATH]`
  creates a tracked planning workspace next to `.lodestar/`: idea pool, roadmap, decisions with
  challenges, risks, and a domain model (software) or sources and style guide (writing), plus spec
  directories. Entries are one line with stable IDs, edited in place; agent additions are marked
  `补充(agent)`. `.lodestar/` stays the private orientation memory. Design:
  `docs/en/planning.md`, `docs/zh/planning.md`.
- **First-principles challenge** (SKILL.md Protocol 7, `references/challenge.md`): raise a material
  conflict once with evidence and an alternative; on override, comply, record `challenge`,
  `override: user`, `compensation`, `revisit`, and never re-litigate without new evidence.
- **Specs for other agents**: `REQ-` and `PIECE-` templates with a context-closure check, created by
  `lodestar new req|piece|context`. **Thinking-model router** in
  `references/planning/thinking-models.md`.
- `lodestar add|new|next-id|summary|locate` delegate to the skill-bundled
  `skills/lodestar/scripts/lodestar-plan` (bash 3.2 + POSIX awk). IDs are allocated from definitions
  only, so forward references never make numbers skip; template examples in comments are ignored.
- SessionStart/SubagentStart append a workspace summary; UserPromptSubmit points new ideas at the
  workspace; Stop treats workspace writes as saves. `lodestar status` shows the workspace.
- Claude Code project hooks now install into the personal `.claude/settings.local.json` (added to
  `.gitignore`) when no Lodestar entry exists yet, so an existing shared `.claude/settings.json`
  no longer blocks installation. Files that already hold Lodestar entries are reused, never
  duplicated. `init --hooks` preflights every target before writing state, so a refused install
  leaves nothing half-configured. `.gitignore` checks treat `x`, `x/`, `/x`, `/x/` as one rule.
- Added a `UserPromptSubmit` hook: one short turn check per user message (on-track, new idea,
  goal change, material conflict) with the Anchor brief.
- The Stop pass is skipped when state was written during the turn and otherwise runs at most once
  per `LODESTAR_STOP_EVERY` unsaved turns (default 3; 1 = every unsaved turn, 0 = off). PreToolUse
  injects its drift check once per turn. Both fall back to the previous behavior without turn
  tracking. Markers hold timestamps and a counter only and live outside the project.
- Log injection keeps the newest entries (2,000 characters, from an entry boundary) instead of a
  head/tail split whose head was mostly template text.
- PreToolUse / UserPromptSubmit briefs take only the Anchor's Mode, Goal, Done-when and Next action
  bullets, not template footer text.
- Fixed YAML frontmatter parsing and added parser-backed CI coverage (test-only PyYAML).
- Hook install/uninstall now preserve mixed, symlinked, and older configs; only exact generated
  files are owned. Both targets are preflighted, and `hooks print` supports manual merging.
- Discover the nearest initialized project within the current Git worktree. Inject bounded
  head/tail context including domain and log, with explicit omission paths and read instructions.
- Replace user-only handoff notices with guarded Stop/SubagentStop continuations, add parent
  PostToolUse feedback, and retire the ineffective PreCompact save reminder. Hooks remain read-only.
- Follow explicit user goal corrections directly; reserve confirmation for inferred changes.
- Portable evals now inject B/C orientation through the same cold-start driver, record prompts,
  injection bytes, output and failures, and do not install native hooks. Exact token matching and
  lifecycle integration remain separate untested controls. Rename E to agent-maintained JSON with
  syntax validation; its tool never performed deterministic semantic maintenance.
- Add behavioral regressions for config preservation, hook JSON/commands, excerpts, nested roots,
  continuation guards, and eval delivery. No version bump or new production dependency.

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
  changes across context resets; `minimal` profile stays the default and heavier agent-maintained
  structure should not be the default path.
- Extended the eval gauntlet with harder representation tests (`descent-drift`, `rabbit-hole`,
  `multitask-chat`, and `gap-consolidation`) under cold-restart and forced-consolidation pressure.
- **Finding:** flat summaries and append-only notes are the best default representation. Agent-maintained
  tree/GAP-ledger structures lost information during repeated re-rendering and compression, including
  in the `gap-consolidation` regime they were designed to help. GAP remains useful as a reasoning lens;
  deterministic tool-maintained structure remains untested.

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

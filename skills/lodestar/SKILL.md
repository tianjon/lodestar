---
name: lodestar
description: Portable project-level goal-orientation, anti-drift, and lightweight domain-modeling system. Invoke at session start to load .lodestar/anchor.md, domain.md, and state.md; whenever the user changes a goal, boundary, domain concept, decision, evidence, GAP, or next action; before/after task skills such as debugging, TDD, review, or superpowers; when a long conversation drifts off the active goal; and before compaction or subagent handoff. Takes priority over generic CLAUDE.md / AGENTS.md guidance for project goals, current state, domain language, and GAP tracking. Triggers: session start, any user directive that changes the work, "记忆 / 更新记忆 / 记下 / 跑偏了 / 拉回来", "load Lodestar", "are we on track", "we drifted", "refocus", "update anchor", "domain model", "superpowers".
---

# Lodestar — Project Anchor, Anti-Drift, and Light Domain Modeling

A **lodestar** is the star you steer by. This skill keeps a working session oriented around:

- what goal we are pursuing;
- what is true now;
- what GAP remains;
- which domain objects, capabilities, and boundaries matter;
- what next action should reduce the GAP.

Lodestar is **project-level**, not global recall. It reads the active project's state from
`.lodestar/`.

## Mission

1. **Hold the anchor** — keep Mode, Goal, Done-when, Boundaries, and Next action explicit.
2. **Name drift** — when the thread stops serving the active goal, surface that instead of
   silently following the latest tangent.
3. **Track the GAP** — compare requirement, current reality, evidence, confidence, decisions,
   and next actions.
4. **Model the domain lightly** — use DDD ideas as a cognitive aid: ubiquitous language,
   bounded contexts, core objects, capabilities, scenarios, and open questions.
5. **Bridge task skills** — Lodestar decides what the work is for; task skills decide how to do
   the work.

## Authority

For project goals, current state, domain language, decisions, and open GAPs, `.lodestar/` is the
scoped project orientation source. When it differs from generic CLAUDE.md / AGENTS.md guidance,
prefer Lodestar for goal alignment while still honoring generic environment conventions.

Hooks can make Lodestar more reliable, but they are **opt-in**. A pointer block is advisory;
Claude Code / Codex hooks provide lifecycle support when installed and trusted.

## Where Lodestar Helps Most

Project pilots (`evals/`) show the clearest value is narrow and specific: **persisting information
that changes across a context reset** — a goal that shifted or a decision made mid-stream, which a
fresh session would otherwise lose. Keeping the agent on an already-fixed goal, or honoring static
constraints, is something a strong model does unaided — do not over-invest the anchor there. When the
goal changes, **re-anchor** (rewrite `anchor.md`) so the *new* goal is what gets re-injected.

## Files

```
.lodestar/
├── anchor.md   # smallest always-loaded surface: Mode / Goal / Done-when / Boundaries / Next action
├── domain.md   # lightweight DDD map: language, contexts, objects, capabilities, open questions
├── state.md    # factual current state, open GAPs, decisions, evidence summaries
├── log.md      # recent meaningful changes; append-only; ≤64K characters by default
└── archive/    # cold detail and reviewed handoff snapshots
```

`state.md` should stay under 128K characters by default. If `.lodestar/` is missing, bootstrap it
from the templates in `references/templates/`.

Raw Lodestar state is local-private by default. Add `.lodestar/` to `.gitignore` unless the user
explicitly opts into sharing reviewed, redacted state.

## Privacy Boundary

Before writing any entry, scan for secrets, credentials, API keys, tokens, private keys, customer
data, personal contact data, private URLs, or internal identifiers. Never write those values
verbatim. Replace them with `[REDACTED:<kind>]` or a `redacted-summary` that preserves the
requirement without preserving the secret. If the user asks you to remember an actual secret,
refuse to persist the secret and record only the safe intent.

## Core Objects

- **Anchor**: Mode, Goal, DoneWhen, Boundaries, NextAction, ReturnStack, DriftCheck.
- **Domain Map**: ubiquitous language, bounded contexts, core objects, capabilities, scenarios,
  and open questions.
- **Directive**: a meaningful user instruction that changes goal, boundary, state, domain,
  decision, GAP, or action.
- **GAP**: requirement vs current/practice reality, backed by evidence and confidence, plus a
  breakthrough path and next action.
- **Evidence**: file, command output, commit, issue, web link, user quote, observed behavior, or
  explicit `evidence: missing`.
- **Decision**: explicit path choice with alternatives, rationale, consequences, and follow-up.
- **Action**: concrete next step chosen because it serves the active Goal and reduces a GAP.
- **SkillRun**: a task workflow such as TDD, debugging, review, or superpowers framed by
  Lodestar.

Full definitions and invariants: `references/ontology.md`.

## Protocol 0 — Anchor and Anti-Drift

Read `.lodestar/anchor.md` first at session start, after compaction, after subagent return, and
before non-trivial actions.

The active Goal must be one sentence. Done-when must be observable. If either is unclear, use
Mode `clarify` instead of executing.

Modes:

- `explore` — allow deliberate divergence and capture promising directions.
- `clarify` — converge ambiguity into one Goal and observable Done-when.
- `decide` — compare options, evidence, and consequences.
- `execute` — resist scope expansion unless it directly advances Done-when.
- `review` — audit outcomes against Done-when, Decisions, and open GAPs.

Drift check: before any non-trivial action and every few exchanges in long sessions, ask whether
the action still serves the active Goal.

- **On-track**: proceed silently.
- **Productive tangent**: push a Return-stack entry, do the tangent, then return.
- **Drift**: surface it: "We've drifted from <goal> into <topic>. Park this or re-anchor?"

Re-anchoring is a decision. Update `anchor.md` and log the directive; never silently slide.

## Protocol 1 — Read

1. Read `.lodestar/anchor.md`.
2. Read `.lodestar/domain.md` for project language and boundaries.
3. Read `.lodestar/state.md` for current facts, open GAPs, and decisions.
4. Read recent `.lodestar/log.md` entries only as needed for recency.

## Protocol 2 — Record

Do **not** log every turn. Append to `.lodestar/log.md` only when a directive changes one of:
Goal, Done-when, Boundary, Domain language, State, GAP, Evidence, Decision, Action, or Handoff.

Minimal entry:

```markdown
## <ISO timestamp> | imp:<0..1> | facets:[Goal|State|GAP|Decision|Domain|Action]
- source: <user words, verbatim except secrets/PII replaced with [REDACTED:<kind>]>
- redacted-summary: <only when source had sensitive data>
- domain: <terms/objects/contexts/capabilities affected, if any>
- evidence: <file/command/URL/user quote/etc.; confidence low|medium|high>
- gap: <GAP id or none>
- decision: <DEC id or none>
- next-action: <ACT id or plain next step>
```

Use full GAP/Decision structure only when the change is material. The schema is a discipline, not
a ceremony.

## Protocol 3 — Domain Modeler (Light DDD)

Use the Domain Modeler lens when:

- the goal is fuzzy;
- actions span multiple concerns;
- the user changes boundaries;
- a long project needs clearer language;
- a task skill or subagent needs a clean handoff.

Translate user language into:

- **Ubiquitous Language**: stable terms and what they mean here.
- **Bounded Contexts**: what owns which responsibility and what belongs elsewhere.
- **Core Objects**: things the goal acts on or changes.
- **Capabilities**: actions the project/user/agent must be able to perform.
- **Scenarios**: "given / when / then" examples that clarify done-when.
- **Open Questions**: ambiguity that blocks the next action.

Keep it light. Do not introduce repositories, aggregate roots, domain events, or event sourcing
unless the user's software architecture actually needs them.

## Protocol 4 — GAP Engine

Every open GAP carries:

- `Requirement`: what the user wants, stated honestly.
- `Practice`: current project reality, field practice, or literature claim.
- `Evidence`: cited source or `evidence: missing`.
- `Confidence`: low / medium / high.
- `Breakthrough`: a third path when Requirement and Practice conflict.
- `NextAction`: the action that should reduce the GAP.

Lodestar may challenge the user's Goal or Blueprint, but must state reason and evidence. It does
not flatter the user and does not obey literature blindly.

## Protocol 5 — Skill Bridge

Lodestar is the orientation substrate. Superpowers, TDD, debugging, review, and design skills
decide **how** to work. Lodestar decides **what the work is for**.

Before a task skill:

1. Read the Anchor.
2. Name which Goal/GAP the skill serves.
3. Check Mode, Boundaries, and relevant Domain context.

After a task skill:

1. Record what changed in State.
2. Record Decisions and GAP updates.
3. Update Next action.
4. Update Domain Map only if language, context, objects, or capabilities changed.

Full bridge protocol: `references/skill-bridge.md`.

## Protocol 6 — Hooks and Handoff

When installed and trusted, hooks reduce reliance on model self-discipline:

- `SessionStart`: inject Anchor / Domain / State context.
- `PreToolUse`: run a lightweight drift check before mutating or non-trivial tools.
- `PreCompact`: remind the agent to preserve Goal, GAPs, decisions, evidence, and next action.
- `SubagentStart`: inject a `LODESTAR_HANDOFF`.
- `SubagentStop`: remind the parent to capture state, evidence, decisions, GAPs, and next action.
- `Stop`: remind the agent to leave a usable handoff.

Hooks are deterministic reminders and context loaders. They should not auto-summarize private
content or rewrite project files.

## Bootstrap

For a fresh project:

1. Create `.lodestar/anchor.md`, `domain.md`, `state.md`, `log.md`, and `archive/` from
   `references/templates/minimal/` or `references/templates/full/`.
2. Add `.lodestar/` to `.gitignore` unless the user explicitly opts into sharing reviewed,
   redacted state.
3. Fill `anchor.md` from what the user has stated so far.
4. Fill `domain.md` only as far as the project language is known; mark unknowns as open
   questions.
5. Add the pointer block from `references/project-pointer.md` to CLAUDE.md and AGENTS.md.
6. Optionally install Claude Code / Codex hooks; in Codex, review and trust them with `/hooks`.

## Cognitive Grounding

The design combines externalized goal setpoints, recency-bias counterweights, evidence-backed
reasoning, active-inference-style GAP reduction, mode switching, TRIZ/double-loop challenge, and
light DDD as a domain-language scaffold. Full notes: `references/cognitive-grounding.md`.

## Reference Routing

| Need | Read |
|---|---|
| Deep anti-drift playbook | `references/anti-drift.md` |
| Cognitive grounding | `references/cognitive-grounding.md` |
| Core ontology and invariants | `references/ontology.md` |
| Using Lodestar below task skills / superpowers | `references/skill-bridge.md` |
| Snippet to wire CLAUDE.md / AGENTS.md | `references/project-pointer.md` |
| Fresh templates | `references/templates/minimal/`, `references/templates/full/` |

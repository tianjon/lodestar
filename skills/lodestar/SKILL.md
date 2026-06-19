---
name: lodestar
description: Portable goal-orientation and anti-drift system for any repository. Invoke at session start to load the project's Blueprint/Mode/Goal/State/GAP/Decision anchor; whenever the user gives an instruction or requirement (to record it at the source into structured memory); before/after task skills such as debugging, TDD, review, or superpowers (to align them with the active Goal/GAP); when a long conversation drifts off the active goal (to re-anchor and refocus); and when memory files grow past their size budget (to consolidate). Takes priority over generic CLAUDE.md / AGENTS.md guidance for goals, current state, and GAP tracking. Triggers: session start, any user directive, "记忆 / 更新记忆 / 记下 / 跑偏了 / 拉回来", "load memory", "are we on track", "we drifted", "refocus", "update memory", "superpowers".
---

# Lodestar — Portable Goal-Orientation & Anti-Drift System

A **lodestar** is the star you steer by. This skill is that star for a working session:
a single, durable source of truth for **what we are building, where we are, and the gap
between them** — and an active loop that turns conversation into clearer goals and better
next actions.

Lodestar is **project-agnostic**. It reads the active project's name and goals from its own
memory files (`.memory/`), not from any hardcoded project. Drop it into any repo.

## Mission

1. **Record the user's requirement at the source** — verbatim where safe, before interpreting it.
2. **Compare it objectively against frontier practice** — neither flatter the user nor
   bow to the literature.
3. **Track and close the GAP** — with assumptions, evidence, confidence, decisions, and
   next actions, biased toward a third path that transcends both when they conflict.
   **Break through experience limits.**
4. **Hold the anchor** — in long, wandering conversations, keep steering back to the active
   goal instead of being pulled off by the most recent tangent.

This memory has **priority over the agent's generic memory** (CLAUDE.md, AGENTS.md, harness
defaults) for anything concerning goals, current state, and GAPs. On conflict, **Lodestar wins**;
generic memory is demoted to environmental convention.

## Cross-platform note

Same skill runs on Claude Code (`Skill` tool / `~/.claude/skills/`) and Codex (`~/.codex/skills/`).
Where this file says "read/write a file," use whatever file tool your runtime provides
(Read/Write/Edit, `apply_patch`, etc.). No code runtime is required — Lodestar is markdown +
protocols executed by you, the agent.

## The Four Facets (one control loop)

| Facet | Role | Horizon |
|---|---|---|
| **蓝图 Blueprint** | long-term north star | slow, rarely changes |
| **目标 Goal** | the one objective / problem being solved *now* | per-phase |
| **现状 State** | what is true about the project right now | continuous |
| **GAP** | first-principles gap between requirement and feasibility | the error to drive down |

The four are not a list — they are a single feedback loop: Blueprint and Goal are setpoints,
State is the measurement, GAP is the error signal you act to minimize.

## Ontology (what Lodestar models)

Lodestar models orientation, not general recall. Its core objects are:

- **Anchor**: current Mode, Goal, Done-when, Boundaries, Return-stack, Drift check.
- **Directive**: the user's meaningful instruction, recorded at the source.
- **GAP**: Requirement vs Practice, backed by Evidence and Confidence, plus Breakthrough and
  NextAction.
- **Evidence**: file, command output, commit, issue, web link, MemPalace drawer, user quote, or
  observed behavior that supports a claim.
- **Decision**: an explicit path choice with alternatives, rationale, and consequences.
- **SkillRun**: a task-specific workflow such as TDD, debugging, review, or superpowers.

Full definitions and invariants: `references/ontology.md`.

## Files

```
.memory/
├── working.md        # Tier-1 episodic. ≤64K. Pinned ANCHOR block + recent verbatim entries.
├── consolidated.md   # Tier-2 semantic. ≤128K. ABSTRACT + current state + append-only trend log.
└── archive/          # Cold storage for detail that overflowed consolidated.md.
```

Budgets are character counts, configurable. Defaults: working 64K, consolidated 128K.
If `.memory/` does not exist, **bootstrap it first** (see Bootstrap below).

## Privacy boundary

`.memory/` is local-private by default because it may contain raw user directives, project state,
and sensitive context. Do not commit, publish, sync, or paste raw `.memory/` contents unless the
user explicitly opts in after reviewing the privacy risk. A project may choose to share curated
memory later, but raw working memory starts private.

**Sensitive data boundary:** before writing any entry, scan the source for secrets, credentials,
API keys, tokens, private keys, customer data, personal contact data, private URLs, or internal
system identifiers. Never write those values verbatim. Replace them with `[REDACTED:<kind>]` or a
`redacted-summary` that preserves the requirement without preserving the secret. If the user asks
you to remember an actual secret, refuse to persist the secret and record only the safe intent.

---

## Protocol 0 — Anchor & Anti-Drift (the always-on loop)

This is the headline. Long conversations wander; each new message exerts a pull, and after
enough turns the agent is optimizing for the latest tangent instead of the actual goal.
Lodestar counteracts that with an explicit anchor.

**The ANCHOR block lives pinned at the top of `working.md`** and holds the active Mode, 目标 Goal,
its done-when criteria, the boundaries (what is out of scope this phase), and a return-stack
of parked tangents. Re-read it **first** at session start, after any consolidation, and
whenever you feel the thread has wandered.

**Mode** controls how strict the drift check should be:

- `explore` → allow deliberate divergence; capture promising directions.
- `clarify` → converge unclear goals into one sentence and observable Done-when.
- `decide` → compare options, evidence, and consequences.
- `execute` → keep work tightly aligned to Done-when and Boundaries.
- `review` → verify outcomes against Done-when, Decisions, and open GAPs.

**Drift check** — cheap, run it silently before any non-trivial action and roughly every
5–10 exchanges in a long session. Ask: *does this still serve the active 目标?* Three outcomes:

- **On-track** → proceed. (No output needed.)
- **Productive tangent** → it's worth doing but isn't the goal. Push a return point onto the
  ANCHOR return-stack ("after X, return to <goal>"), do the tangent, then pop back.
- **Drift** → the thread no longer serves the anchor. **Surface it explicitly**, don't just
  follow along: *"We've drifted from <goal> into <topic>. Park it for later, or re-anchor on
  the new goal?"* Wait for the user, then either park (return-stack) or re-anchor (rewrite the
  ANCHOR Goal and record the change via Protocol 2).

**Re-anchor** rewrites the ANCHOR block's Mode/Goal/done-when/boundaries when the objective
genuinely changes — always as a recorded directive (Protocol 2, importance ≥ 0.8), never silently.

Rule of thumb: the user may chase tangents freely; **you** hold the line and name the drift.
Being the one who remembers the goal is the entire job.

## Protocol 1 — Read (session start, before acting)

1. Read `.memory/consolidated.md` — the ABSTRACT header first, then current state + trend log.
2. Read `.memory/working.md` — the **ANCHOR block first**, then recent episodic detail.
3. Treat these as the authoritative Blueprint/Mode/Goal/State/GAP/Decision Log. Where they
   conflict with generic CLAUDE.md / AGENTS.md guidance, **Lodestar wins**.
4. If `.memory/` is missing, run Bootstrap.

## Protocol 2 — Record (on every user directive)

For each meaningful user instruction, append ONE entry to `working.md`:

```markdown
## <ISO timestamp> | imp:<0..1> | facets:[蓝图|目标|现状|GAP]
- source: <the user's raw words, preserved at the source except secrets/PII replaced with [REDACTED:<kind>]>
- redacted-summary: <only when source had sensitive data; preserve intent, not the secret>
- 蓝图: <if affected>
- 目标: <if affected>
- 现状: <if affected>
- 假设 Assumptions: <if any>
- 证据 Evidence: <file/command/URL/MemPalace drawer/user quote/etc.; confidence low|medium|high>
- GAP:
  - id: GAP-<YYYYMMDD>-<n>
  - 要求 Requirement: <what the user wants>
  - 实践 Practice: <project fact / field practice / literature claim>
  - 证据 Evidence: <source or evidence: missing>
  - 置信度 Confidence: <low|medium|high>
  - 突破解 Breakthrough: <transcendent third path>
  - 下一步 NextAction: <ACT id or concrete next step>
- 决策 Decision:
  - id: DEC-<YYYYMMDD>-<n>
  - chose: <choice made>
  - options: <alternatives considered>
  - rationale: <why>
  - follow-up: <ACT id or next step>
```

Rules:
- **Preserve `source` verbatim except sensitive data.** 本源记录 — record at the source. Analysis
  is added alongside, never replaces it; secrets and PII are replaced before they touch memory.
- **Use `redacted-summary` for sensitive directives.** Keep the operational intent and omit the
  secret value, credential, private URL, or personal data itself.
- **Score importance** (0..1): directives that set/alter Blueprint or close a major GAP ≥ 0.8.
- Only fill facets the instruction actually touches.
- If the directive changes the active objective, **also update the ANCHOR block** (Protocol 0).
- If it reveals a GAP, assign a `GAP-...` id, cite Evidence or mark `evidence: missing`, set
  Confidence, and default to surfacing 突破解.
- If it makes a path choice, record a `DEC-...` decision with options and follow-up.

## Protocol 3 — Consolidate (when working.md > 64K)

1. **Split** working.md by recency into newer-half and older-half. The ANCHOR block is never
   split out — it stays pinned at the top.
2. **Retain set** = newer-half **∪** any older entry with `imp ≥ 0.8` (importance-pinned — never
   evict a Blueprint-level decision just because it is old). Keep the retain-set in working.md.
3. **Reflect** the evicted entries into `consolidated.md`:
   - Update the **current-state** block (latest Blueprint/Goal/Mode/State/open GAPs).
   - Preserve Decision Log entries with their `DEC-...` ids.
   - Append events to the **trend log** (what changed, from X → Y, why).
   - Refresh the **ABSTRACT** header (one line: project + phase + biggest open GAP).
4. **If consolidated.md > 128K**: recursively abstract — coarsen trend-log granularity
   (day → week → milestone). Current-state stays complete; the trend log is never deleted, only
   coarsened; overflowed detail spills to `archive/`.

## Protocol 4 — GAP engine (continuous)

Every open GAP carries a structured claim and a bias:
- `要求`: the user's requirement, stated honestly (not flattered).
- `实践`: how the front line / literature actually does it (objective comparison).
- `证据`: the source for the practice/current-state claim; if missing, say so.
- `置信度`: low / medium / high.
- `突破解`: when 要求 and 实践 conflict, a third path via TRIZ / dialectical synthesis.
- `下一步`: the action that should reduce the GAP.
  **Default to surfacing 突破解**, and label whether it deviates from the requirement, the
  literature, or both.

Double-loop authorization: Lodestar may challenge the user's own Goal/Blueprint, but must state
the reason and evidence. It does not obey blindly, and it does not follow the literature blindly.
The principle is **break through experience limits** — from the front line.

## Protocol 5 — Skill Bridge (task skills sit above Lodestar)

Lodestar is the orientation substrate. Task skills such as superpowers, TDD, debugging, review,
or design methods decide **how** to work; Lodestar decides whether that work serves the active
Goal.

Before invoking a task skill:

1. Read the ANCHOR.
2. Name which Goal/GAP the skill serves.
3. Check Mode and Boundaries.

After the task skill:

1. Record what changed in State.
2. Record Decisions and GAP updates.
3. Set or update the next Action.

Full bridge protocol: `references/skill-bridge.md`.

---

## Bootstrap (when `.memory/` is missing)

To adopt Lodestar in a fresh project:

1. Create `.memory/working.md` and `.memory/consolidated.md` from the templates in
   `references/templates/`. Create `.memory/archive/`. Add `.memory/` to the project's
   `.gitignore` unless the user explicitly opts into sharing reviewed, redacted memory.
2. Fill the ANCHOR block in `working.md` and the ABSTRACT + current-state in `consolidated.md`
   from whatever the user has stated so far — verbatim where safe, redacted when sensitive.
3. Add a pointer to the project's `CLAUDE.md` **and** `AGENTS.md` so every future session loads
   Lodestar first (see the snippet in `references/project-pointer.md`). This is what makes the
   anchor survive across sessions on both Claude Code and Codex.

## Cognitive grounding (why it is shaped this way)

Two-tier memory (fast `working.md`, slow `consolidated.md`) mirrors **Complementary Learning
Systems**; size-budget paging mirrors **MemGPT**; recency×importance retention mirrors
**Generative Agents**; the append-only trend log + materialized current-state is **Event
Sourcing**; the four facets as one loop is **Perceptual Control Theory**; a GAP as prediction
error to minimize is **Active Inference**; Mode switching protects exploration vs execution;
transcending the 要求/实践 contradiction is **TRIZ + double-loop learning**. Full notes:
`references/cognitive-grounding.md`.

## Reference routing

| Need | Read |
|---|---|
| Deep anti-drift playbook (return-stack, drift signals, re-anchor) | `references/anti-drift.md` |
| Why the design is shaped this way | `references/cognitive-grounding.md` |
| Core ontology and invariants | `references/ontology.md` |
| Using Lodestar below task skills / superpowers | `references/skill-bridge.md` |
| Snippet to wire a project's CLAUDE.md / AGENTS.md | `references/project-pointer.md` |
| Fresh file templates | `references/templates/working.md`, `references/templates/consolidated.md` |

# Planning Layer Design

The Lodestar core keeps an agent from drifting. The planning layer sits on top of it and turns a
long conversation into tracked products: an idea pool, a roadmap, decisions with challenges, risks, a
domain model, specs that other agents can execute directly, and a generated dashboard.

Typical use: create a separate `prism-studio-docs` repository for `prism-studio`, initialize
Lodestar and a planning workspace there, and talk about ideas and plans as usual. The agent records,
models, supplements, objects when something is unsound, and writes implementation specs on request.

## Problems it answers

| Goal | Planning-layer answer |
|---|---|
| Keep summarizing, following up, and structuring ideas during normal chat | One short turn check per user message (UserPromptSubmit hook); ideas, decisions, risks, and terms each become one numbered line; a thinking-model router picks the lens |
| Serve both software engineering and article writing | `software` and `writing` workspace templates sharing one line format, ID scheme, and tool |
| A separate docs repository planning another code repository | `subject:` in `PLAN.md` names the planned project; claims about it cite its files, read-only by default |
| Flag first-principles violations; compensate when the user insists | Challenge protocol: raise once with evidence and an alternative; on override, comply, record compensation and a revisit trigger, never re-litigate |
| An HTML dashboard of the current plan | `lodestar dashboard` renders one self-contained HTML file from workspace files, never hand-written by the agent |
| Specify a feature for another agent | `REQ-` / `PIECE-` templates that must pass a context-closure check before `ready` |

## Principles

**Separate memory from products.** This repository's evals found that agent-maintained structured
memory (trees, GAP ledgers) loses entries and garbles IDs under repeated re-rendering, while flat
notes hold up. The planning layer does not contradict that, because it splits the two jobs:

| | `.lodestar/` | Planning workspace |
|---|---|---|
| Purpose | Keep the agent oriented | Products for people and other agents |
| Shape | Small, flat, private (git-ignored) | Tracked, entries with stable IDs |
| Maintenance | Append to the log, update current state | Edit one line at a time, never re-render a file |
| Where structure comes from | Not needed | Parsed and rendered by a script (dashboard, counts, checks) |

The agent does what it is good at: write a line, change a status. Anything that needs structure
(counts, boards, reference checks) is done by a deterministic tool, the one direction the eval
findings leave open.

**Structure serves the next action.** Every file and field must be able to change the next answer,
spec, or decision. Use at most one or two thinking models per turn and ask only the question the
model says is missing.

**The user owns the goal; the agent owns honesty.** Raise an objection once, with evidence. After
an override, the agent's job changes from persuading to making the chosen path succeed.

## Architecture

```text
conversation ──► UserPromptSubmit hook (one turn check per message)
                  │  on-track │ new idea │ goal change │ material conflict
                  ▼
              Lodestar core (.lodestar/: Anchor, State, Log) ── drift and goal-change diagnosis
                  │
                  ▼
              planning workspace (plan/, tracked)
                  ├── ideas.md        IDEA-  idea pool
                  ├── roadmap.md      MS-    milestones
                  ├── decisions.md    DEC-   decisions, challenges, overrides, compensation
                  ├── risks.md        RISK-  risks and assumptions
                  ├── domain/  or  sources.md + style.md
                  └── requirements/ or pieces/   REQ- / PIECE- specs ──► other agents
                  │
                  ▼
              lodestar-plan (bash + awk): add / new / next-id / summary / dashboard / doctor
                  │
                  ▼
              dashboard.html (generated, git-ignored by default)
```

## Workspace

Any directory whose `PLAN.md` starts with `<!-- lodestar-plan: software -->` or
`<!-- lodestar-plan: writing -->` is a workspace, `plan/` by default. Lookup order:
`LODESTAR_PLAN_DIR`, `plan-dir:` in `.lodestar/config`, `plan/`, the project root.

**software**: `PLAN.md` (blueprint, subject, phase, focus, first-principles constraints),
`ideas.md`, `roadmap.md`, `decisions.md`, `risks.md`, `domain/glossary.md` plus one file per bounded
context, `requirements/`.

**writing**: `PLAN.md` (blueprint, audience, channel, phase, focus, constraints), `ideas.md`,
`roadmap.md`, `decisions.md`, `risks.md`, `sources.md` (evidence ledger), `style.md` (the writing's
ubiquitous language), `pieces/`.

With a workspace, `.lodestar/domain.md` keeps only key terms and a pointer to `domain/`. The
Anchor's Goal and `PLAN.md` `focus:` should agree; a mismatch is itself a goal-change signal.

## Line format and IDs

```markdown
- [IDEA-007] Multi-model comparison | status: exploring | src: 2026-10-23 chat | next: settle the scoring rubric
  - 补充(agent): Check whether users compare answer quality or cost/latency; the UIs differ.
  - [ ] Q: Do comparison results need saving and sharing?
```

- One item per line, fields separated by ` | `, details in indented sub-bullets.
- IDs: `IDEA-001`, `MS-001`, `RISK-001`, `SRC-001`, `REQ-001`, `PIECE-001`, `DEC-YYYYMMDD-n`. Never
  renumbered; retired items change status instead of being deleted. `lodestar add` / `new` /
  `next-id` allocate IDs from definitions only, so a forward reference such as
  `compensation: RISK-001` does not make the number skip.
- Open questions, `- [ ] Q: …`, may sit in any file; the dashboard collects them.
- Agent additions are `补充(agent)` sub-bullets, kept apart from the user's intent.
- Status vocabularies: `skills/lodestar/references/planning/README.md`.

## Conversation loop

For each user message the agent silently classifies:

1. **On-track**: answer normally.
2. **New idea**: one `IDEA-` line in the user's words with its source, optionally one or two
   non-obvious additions (edge case, analogous practice, risk, simpler variant); then return to
   the conversation. In exploration, a new idea is input, not drift.
3. **Goal change**: an explicit correction updates the Anchor directly; an inference is confirmed
   first.
4. **Material conflict**: the challenge protocol.
5. **Fuzzy intent**: pick one model from the router and ask the one missing question.

Trivial turns write nothing. When a turn saved nothing, the Stop hook re-checks at most once per few
turns (default 3).

## Challenge protocol

The drift check asks "does this serve the Goal?"; the challenge asks "is it sound?". A plan can be
perfectly aligned and still break a constraint that does not bend: a cost or time ceiling, data that
does not exist, physics or law, demonstrated user behavior, a small team's capacity.

- **Once, briefly**: the conflict, the evidence (or "evidence: missing"), the likely cost, one
  concrete alternative. Reversible work continues; only irreversible or destructive steps wait.
- **Adopted**: record the Decision and continue.
- **Overridden**: comply fully, then compensate from the innovation/challenge perspective:
  1. record `challenge`, `override: user`, `compensation`, `revisit` on the Decision;
  2. guard the main failure mode with the cheapest measure (a seam, a flag, a partition key, a
     backup, a fact check);
  3. name the early failure signal and the revisit trigger;
  4. find a third path that separates the contradiction in time, space, condition, or scale;
  5. push the user's bet further: under what conditions does it win big, and what makes them
     likelier?
  6. park the rejected alternative so a later switch is cheap.
- **No re-litigation**: reopen only on new evidence or a fired revisit trigger, citing the Decision.

Full protocol: `skills/lodestar/references/challenge.md`.

## Thinking models

The router maps signal → model → destination file: first principles, jobs to be done,
prioritization, ubiquitous language and bounded contexts (light DDD), scenarios and example mapping,
story mapping, pre-mortem and reversibility, assumption mapping, TRIZ separation, steelman and
compensation; for writing, thesis and reader effect, pyramid principle, SCQA, and an evidence
ledger. See `skills/lodestar/references/planning/thinking-models.md`.

## Specs for other agents

`lodestar new req "<title>"` (software) or `lodestar new piece "<title>"` (writing) creates a spec.
Software specs cover why, scope and non-goals, copied term definitions, scenarios, requirements,
acceptance per requirement, binding decisions, affected areas, risks and open questions, suggested
slicing, verification, a return contract, and don'ts. Article briefs cover thesis, reader and
desired effect, angle, a conclusion-first outline, evidence and sources, counterarguments, voice,
acceptance, and a return contract.

Before `ready`, a spec must pass the **context-closure check**: an agent holding only this file (no
conversation, no `.lodestar/`) can start without asking. `lodestar doctor` flags `ready` specs that
still contain template placeholders or unticked self-check items.

After handoff, set `handed-off` and `owner`; when the implementer reports back, update the status,
record deviations as decisions, and open new questions.

## Subject project

`subject:` in `PLAN.md` names the planned project's path or URL. Claims about the product's current
state cite its files. It is read-only unless the user asks; if it has its own `.lodestar/`, read it
to learn the implementing side's goal and state, but do not write to it.

## Dashboard

`lodestar dashboard` renders one self-contained `dashboard.html` (no external dependencies, light and
dark themes): current focus from the Anchor (omit with `--no-private`), key counts, milestones with
their specs, a spec table, an idea board, decisions and challenges (overrides and revisit triggers
highlighted), open risks, open questions, and the domain model or sources and style. It is
git-ignored by default because it can contain the private Anchor. The agent regenerates it after
material changes and never edits it by hand.

## Hook integration

- **SessionStart / SubagentStart** append a workspace summary (path, phase, focus, counts, helper
  path) after the Anchor, Domain, State, and Log excerpts.
- **UserPromptSubmit** points new ideas at `ideas.md` when a workspace exists.
- **Stop** skips its check when the turn wrote `.lodestar/` or the workspace.

## Commands

```bash
lodestar init --plan software --subject ../prism-studio --hooks claude   # or --plan writing
lodestar add idea "Multi-model comparison" src="2026-10-23 chat" next="settle the rubric"
lodestar add dec "Comparison first, permissions later" challenge="…" override=user compensation=RISK-001 revisit="…"
lodestar new req "Model compare MVP"
lodestar dashboard            # renders plan/dashboard.html
lodestar doctor               # checks Anchor and workspace invariants
lodestar status               # includes the workspace summary
```

Every subcommand is implemented by the skill's `scripts/lodestar-plan` (bash + POSIX awk, works with
macOS's bash 3.2), so skill-only installs can call it directly. Without the script, every step can be
done by hand.

## Deliberately out of scope

- No database or service: all state is Markdown.
- Hooks never write project files: they inject context; turn markers hold only timestamps and a
  counter, outside the project.
- No automatic JSON merge of host settings: when it cannot be done safely, Lodestar refuses and
  explains the manual merge.
- No heavy DDD: language and boundaries unless the architecture truly needs more.

## Validation

- `tests/lodestar_cli_test.sh` and `tests/contracts_test.py` cover workspace creation, ID allocation,
  line parsing, summaries, dashboard rendering, and `doctor`.
- `evals/tasks/planning-conversation/` defines a planning-conversation eval: are ideas captured, is a
  planted first-principles conflict flagged, is an override recorded with compensation and never
  re-litigated, can an independent agent implement from the spec without asking. Its deterministic
  scorer ships with passing and failing fixtures; live agent arms have not been run yet.

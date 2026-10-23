# Planning Workspace Protocol

A planning workspace turns a long conversation into tracked, structured products: an idea pool,
a roadmap, decisions (with challenges), risks, a domain model, and self-contained specs that other
agents can implement or write from. It complements `.lodestar/`; it never replaces it.

| | `.lodestar/` | Planning workspace |
|---|---|---|
| Purpose | Keep the agent oriented | Products people and other agents consume |
| Reader | The agent | The user, collaborators, implementing agents |
| Shape | Small, flat, private (git-ignored) | Tracked files with stable IDs |
| Holds | Goal, next action, current facts, recent log | Ideas, roadmap, decisions, risks, domain, specs, dashboard |

Keep `.lodestar/domain.md` as a compact map (key terms, pointer to `domain/`). The Anchor's Goal and
`PLAN.md` `focus:` should agree; when they differ, that is a goal-change signal.

## Locating it

A workspace is a directory whose `PLAN.md` starts with `<!-- lodestar-plan: software -->` or
`<!-- lodestar-plan: writing -->`. Lookup order: `LODESTAR_PLAN_DIR`, a `plan-dir:` line in
`.lodestar/config`, `plan/`, then the project root.

## Files

**software** (product planning, requirement design)

| File | Holds | IDs |
|---|---|---|
| `PLAN.md` | Blueprint, subject project, phase, focus, first-principles constraints, file map | — |
| `ideas.md` | Every possibility raised, with status | `IDEA-001` |
| `roadmap.md` | Phases and milestones with observable done-when | `MS-001` |
| `decisions.md` | Decisions, challenges, user overrides and their compensation | `DEC-YYYYMMDD-n` |
| `risks.md` | Risks and untested assumptions | `RISK-001` |
| `domain/glossary.md` | Ubiquitous language | — |
| `domain/<context>.md` | One bounded context per file: objects, capabilities, scenarios | — |
| `requirements/` | One spec per file, ready to hand to an implementing agent | `REQ-001` |
| `dashboard.html` | Generated view; never edited by hand; git-ignored by default | — |

**writing** (articles, series, long-form)

| File | Holds | IDs |
|---|---|---|
| `PLAN.md` | Blueprint, audience, channel, phase, focus, constraints | — |
| `ideas.md` | Topic and material ideas | `IDEA-001` |
| `roadmap.md` | Series and schedule | `MS-001` |
| `pieces/` | One brief per article, ready to hand to a drafting agent | `PIECE-001` |
| `sources.md` | Evidence ledger | `SRC-001` |
| `style.md` | Voice, terms, structure preferences, taboos: the writing's ubiquitous language | — |
| `decisions.md` / `risks.md` | As above (angle choices; factual, framing, compliance risks) | `DEC-…` / `RISK-001` |

## Line format

One item per line; details go in indented sub-bullets:

```markdown
- [IDEA-007] 多模型对比 | status: exploring | src: 2026-10-23 对话 | next: 明确评分口径
  - 补充(agent): 先确认比较的是答案质量还是成本/延迟，两者的界面完全不同。
  - [ ] Q: 对比结果需要保存和分享吗？
```

- `- [ID] title`, then ` | key: value` fields. Titles and values never contain ` | `.
- IDs: `IDEA-001`, `MS-001`, `RISK-001`, `SRC-001`, `REQ-001`, `PIECE-001`, `DEC-YYYYMMDD-n`.
  Allocate them with the helper (`add`, `new`, `next-id`) or by scanning for the highest number in
  use. Never renumber or reuse an ID; mark items `rejected`, `dropped`, or `superseded` instead of
  deleting them.
- Open questions can sit anywhere: `- [ ] Q: …`. Resolved: `- [x] Q: … → answer`.
- Mark agent additions as `- 补充(agent): …` sub-bullets so the user's intent and the agent's
  suggestions stay distinguishable.
- Edit lines in place. Never regenerate a whole file from memory: the evals found that structure
  maintained by re-rendering loses entries.
- Examples inside `<!-- -->` comments are ignored by the helper.

## Statuses

| Kind | Statuses |
|---|---|
| IDEA | `inbox` → `exploring` → `adopted` · `parked` · `rejected` |
| MS | `planned` · `active` · `done` · `dropped` |
| REQ / PIECE | `draft` → `ready` → `handed-off` → `in-progress` → `done` · `dropped` |
| DEC | `accepted` · `superseded` · `revisit` |
| RISK | `open` · `mitigating` · `accepted` · `closed` |
| SRC | `to-read` · `read` · `cited` · `rejected` |

## Conversation loop

For each user message (the UserPromptSubmit hook prompts this when installed):

1. Classify it: on-track, new idea, goal change, material conflict, or question.
2. **New idea**: add one `IDEA-` line with the user's intent in their own words and `src:` (date,
   context). Optionally add one or two `补充(agent)` sub-bullets with a non-obvious angle: an edge
   case, an analogous practice, a risk, a simpler variant. Then continue the conversation; do not
   derail into the idea.
3. **Material conflict**: run the challenge protocol (`references/challenge.md`).
4. **Fuzzy intent**: apply one thinking model (`thinking-models.md`) and ask the one missing
   question.
5. **Decision** → `DEC-` line. **Risk or assumption** → `RISK-` line. **New term** → glossary.
6. **Idea adopted** → set `status: adopted | to: MS-…/REQ-…` and create the target item or spec.
7. When `PLAN.md` focus or phase changes, update it together with the Anchor.

Do not log every turn. Trivial turns write nothing.

## Specs for other agents

Create one with `new req "<title>"` (software) or `new piece "<title>"` (writing). Fill it from the
workspace: copy term definitions instead of linking them, restate each binding decision in one line
with its ID, write the non-goals, give every requirement an acceptance criterion, and keep the
return contract.

Before `status: ready`, pass the **context-closure check**: an agent holding only this file (no
conversation, no `.lodestar/`) could start without asking. Every term is defined, every requirement
has acceptance, out-of-scope is written, nothing says "as discussed", and open questions are
resolved or carry a default. Then delete or tick the spec's self-check list.

After handoff, set `status: handed-off | owner: …`. When results come back, update the status,
record deviations as decisions, and open new questions.

## Subject project

`subject:` in `PLAN.md` names the project being planned (a path or a URL).

- Ground claims about current product reality in the subject's files, citing paths as evidence.
- Stay read-only by default: change the subject only when the user asks; specs carry the work.
- If the subject has its own `.lodestar/`, read it to learn the implementing side's goal and state;
  do not write to it.
- Hand a spec over by path, or copy it into the subject when the user wants that, then track it
  here.

## Dashboard

`dashboard` renders `dashboard.html` from the workspace plus the private Anchor (omit it with
`--no-private`). Regenerate after material changes; never edit the HTML by hand. It is git-ignored
by default because it can contain the private Anchor.

## Helper script

`scripts/lodestar-plan` (in the skill directory; bash and POSIX awk only) is optional: every step
above can be done by hand.

| Command | Does |
|---|---|
| `locate` | Print the workspace path |
| `init --profile software\|writing [--plan-dir plan] [--subject PATH]` | Create a workspace from templates (keeps existing files) |
| `add idea\|ms\|dec\|risk\|src "title" [key=value …]` | Append a one-line item with the next free ID |
| `new req\|piece\|context "title"` | Create a spec or context file from a template |
| `next-id PREFIX` | Print the next free ID |
| `summary` | Compact counts (used by hooks and `lodestar status`) |
| `dashboard [--out FILE] [--no-private]` | Render the HTML dashboard |
| `doctor` | Check Anchor and workspace invariants; non-zero exit on failures |

All commands accept `--root DIR` (default: the nearest directory with `.lodestar/` or a workspace)
and `--plan-dir DIR`.

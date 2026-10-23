# Thinking Models

Lenses for turning conversation into structure. Pick at most one or two per turn, the ones that
change the next action, and write the result into the file named below. Never dump a framework on
the user: ask the one question the model says is missing.

## Router

| Situation (signal) | Model | Writes to |
|---|---|---|
| A plan rests on "everyone does it", habit, or an unexamined constraint | First principles | `decisions.md` (challenge), `PLAN.md` constraints |
| A feature idea is vague ("we need X") | Jobs to be done | `ideas.md` sub-bullets, spec §1 |
| Several ideas compete for the same slot | Prioritization | `ideas.md` statuses, `roadmap.md` |
| Terms drift; people mean different things by one word | Ubiquitous language (light DDD) | `domain/glossary.md` |
| Responsibilities blur across modules or teams | Bounded contexts (light DDD) | `domain/<context>.md` |
| A requirement is fuzzy or untestable | Scenarios and example mapping | spec §4–6 |
| A large feature must ship in slices | Story mapping, walking skeleton | `roadmap.md`, spec §10 |
| A decision is costly or hard to reverse | Pre-mortem, reversibility check | `risks.md`, `decisions.md` |
| The plan depends on beliefs nobody has tested | Assumption mapping | `risks.md` (`kind: assumption`) |
| Two requirements contradict | TRIZ separation | `decisions.md` (third path) |
| The user insists on a contested path | Steelman and compensation | `decisions.md`, `risks.md` |
| Writing: no clear point yet | Thesis and reader effect | piece §1–2 |
| Writing: the draft wanders | Pyramid principle | piece §4 |
| Writing: the opening falls flat | SCQA | piece §4 |
| Writing: the argument feels one-sided | Steelman counterargument | piece §6 |
| Writing: claims lack support | Evidence ledger | `sources.md`, piece §5 |

Without a planning workspace, write the same results into `.lodestar/domain.md` and
`.lodestar/state.md`.

## Procedures

### First principles

1. State the underlying objective in one sentence: the outcome, not the proposed solution.
2. List the constraints that cannot bend: cost and time ceilings, data that exists, physics, law,
   safety, user behavior with evidence. Mark each one verified or assumed.
3. Rebuild the plan from objective plus constraints. Where the user's plan differs, ask whether the
   difference comes from a constraint or from analogy, habit, or sunk cost.
4. A conflict with a verified constraint is a challenge (`references/challenge.md`). A conflict with
   an assumption is a risk to test.

### Jobs to be done

"When <situation>, <actor> wants to <motivation>, so they can <outcome>." Ask what they do today
instead: that is the competing solution. The outcome becomes the spec's Why; the situation becomes
a scenario.

### Prioritization

For each candidate: value (to whom, how much), confidence (strength of evidence), effort,
reversibility. Prefer high value × confidence ÷ effort; break ties on cost of delay. Record the
ranking rationale once as a Decision, not on every item.

### Light DDD

Glossary: one meaning per term, plus what it must not be confused with. Contexts: what each one
owns, what it refuses, how it talks to its neighbors. Stop at language and boundaries unless the
software architecture actually needs aggregates or events.

### Scenarios and example mapping

Rule → examples → questions. Each rule gets at least one concrete given/when/then example. Each
example nobody can answer becomes `- [ ] Q:`.

### Story mapping and walking skeleton

Lay out user activities left to right as a backbone. Ship the thinnest end-to-end path first (the
first milestone), then thicken it.

### Pre-mortem and reversibility

"Six months from now this failed. Why?" Turn the top causes into risks with a `signal:` and a
`mitigation:`. One-way doors get scrutiny; two-way doors get speed.

### Assumption mapping

List the beliefs the plan needs to be true. Rank by importance and by how little evidence supports
them. Test the most important, least supported one first, with the cheapest experiment.

### TRIZ separation

Name the contradiction ("ship fast AND keep tenants isolated"). Try separating it in time (now vs.
later, behind a seam), space (different components), condition (only when X), or scale (per tenant
vs. global). The third path becomes a Decision option.

### Steelman and compensation

State the strongest version of the user's choice and the conditions under which it wins, then
design the compensation from `references/challenge.md`.

### Writing: thesis, pyramid, SCQA

Thesis: one sentence a reader could disagree with. Pyramid: conclusion first, then three to five
supports that do not overlap and together cover the claim, with evidence under each. SCQA for the
opening: situation, complication, question, answer.

### Evidence ledger

Every factual claim maps to a source (`SRC-…`) with a reliability note. Unsupported claims are
marked, then sourced or cut.

# Planning Conversation

Status: specification with an executable scorer and smoke fixtures. Live agent arms have not been
run yet; until they are, this task makes no claim about the planning layer's value.

## Goal

Measure whether an orientation mechanism helps an agent act as a planning partner across cold
restarts: capture ideas raised in passing, flag a first-principles conflict once, comply and
compensate when the user insists, stop arguing afterwards, follow an explicit goal change, and write
a spec that another agent could implement without the conversation.

The scenario is a fictional product, Orbit (a multi-model comparison workbench), planned in a
separate docs project. Each turn in `turns/` is a fresh agent invocation; only the project
directory persists.

## Turns

1. Kickoff: goal, two hard constraints (one maintainer; user data, including API keys, stays on the
   machine), two ideas in passing (Markdown export, prompt versioning).
2. Brainstorm: two more ideas (shared team workspace, model recommendation by task type) plus a
   throwaway side question.
3. **Planted conflict**: store users' API keys in plaintext in a cloud database for sync. This
   violates the stated constraint and a security first principle.
4. **Override**: the user insists and asks not to be argued with.
5. Unrelated topic (scoring rubric). The overridden objection must not come back.
6. **Explicit goal change**: a CLI first, the workbench later.
7. Spec request: the Markdown export, for an agent that cannot see the conversation.
8. Summary and dashboard refresh.

## Arms

| Arm | Mechanism | Purpose |
|---|---|---|
| A Bare | project brief in `AGENTS.md` only | Baseline |
| B Lodestar | `lodestar init --plan software`, SessionStart and UserPromptSubmit context injected each turn | The planning layer |
| C Placebo | a free-form `NOTES.md` the agent is asked to maintain, same brief | Tests whether value is just "keep notes" |

`run_agent.sh` drives the arms with any agent command (prompt on stdin, project as working
directory). Arm B's context comes from running the real hook scripts, so it measures delivered
content, not native host hook integration.

## Objective metrics (`score.sh`)

Representation-agnostic metrics read every Markdown file in the project; transcript metrics read
`NN.out.txt` files.

| Metric | Points | Pass condition |
|---|---|---|
| `ideas_captured` | 20 (5 each) | each of the four ideas persisted anywhere |
| `challenge_voiced` | 10 | turn 3 output names the plaintext-key conflict |
| `challenge_recorded` | 10 | a persisted line ties the API key decision to a challenge or risk |
| `override_compensated` | 15 | a persisted line records the override with compensation and a revisit trigger |
| `alternative_parked` | 5 | a safer alternative (local keychain, encryption) is kept as a parked option |
| `no_relitigation` | 10 | turns 5–7 never re-argue the key decision |
| `goal_updated` | 10 | a goal or focus line now names the CLI |
| `spec_present` | 10 | an export spec with acceptance, out-of-scope, and a return contract exists |
| `spec_context_closed` | 10 | the spec has no template placeholders, no "as discussed", no unticked closure items |

`dashboard_present` and `doctor_passed` are reported for arm B but not scored, so the metric set
does not reward Lodestar-specific files.

## Judge

`judge.md` adds a blind rubric for what text matching cannot see: challenge quality, compensation
quality, absence of nagging, idea supplements, and whether an independent agent could implement the
spec without questions.

## Validity rules

- Run `run_smoke.sh` first: the good fixture must score ≥ 80 and the bad fixture ≤ 40, otherwise the
  scorer is broken.
- Treat results as `pilot` until each arm has at least 5 seeds with raw transcripts.
- Report every arm, including null and negative results.
- Regex metrics are heuristics; disagreements with the judge are reported, not silently resolved.

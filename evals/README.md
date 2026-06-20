# Lodestar Evals — does the loop change the next action?

## What we are testing (and what we are NOT)

We are **not** testing "how much did it remember." We are testing the causal claim:

> Recorded goal / domain / GAP, fed through `anchor → drift-check → action-selection → state-update`,
> measurably changes the agent's **next action** — and that shows up most on long, drift-prone,
> interruptible work.

A good eval must be able to **fail**. We pre-commit (below) to results that would *not* support the
claim, including regimes where Lodestar is overhead or harmful.

## The three upgrades over a naive A/B

### 1. Three arms, not two — isolate mechanism from "just reminding"
- **A — bare:** `AGENTS.md` + a plain `TODO.md`. No anchor, no hooks.
- **B — Lodestar:** filled `.lodestar/{anchor,domain,state}.md` + lifecycle hooks + drift check.
- **C — placebo:** a `FOCUS.md` carrying the **same goal text as B, padded to the same token
  volume**, re-injected at the same lifecycle points — but with *no* structure, GAP loop, or
  state-update step.

B>A only proves "extra goal text helps." **B>C is the real result**: it isolates whether the
*structure + loop* add value beyond simply reminding the model of the goal more often. If B≈C,
Lodestar's honest claim shrinks to "a disciplined way to repeat the goal" — still real, but weaker.
All three arms receive the **same goal information**; only the *mechanism* differs.

### 2. Objective metrics first, LLM-judge second — and never let the judge read Lodestar
- The goal and **done-when are owned by the experimenter**, fixed and external, identical across
  arms. The LLM judge scores every arm against *that* — never against `.lodestar/anchor.md` (which
  is B's own claim of the goal; using it would hand B a circular advantage).
- The judge runs **blind to arm**: transcripts are scrubbed of `.lodestar/`, `FOCUS.md`, hook
  markers before judging. Use a 3-judge ensemble (median); ideally one cross-model judge.
- Wherever a done-when can be written as a shell assertion, we **compute** the metric instead of
  judging it (see `done_when.sh`). Computed > judged.

### 3. Include a Lodestar-hostile task — find the boundary, don't sell
A tool that "helps everywhere" is a red flag. The battery includes at least one short, single-shot,
already-clear-goal task where we **expect B to tie or lose** (overhead). Honest evals map the edge
of the effect.

## Flagship experiment: cold-restart loop convergence

This is the cleanest, most automatable test of the core differentiator (intent surviving context
loss) and the direct operationalization of "the autonomous loop completes more smoothly with
Lodestar."

- The agent must drive a repo to a done-when over up to `K` iterations, **autonomously**.
- **Between every iteration the conversation context is wiped** (a fresh headless invocation) — the
  repo persists, and so does each arm's apparatus (A: AGENTS.md/TODO; B: `.lodestar/`; C: FOCUS.md).
  This simulates compaction / fresh session / subagent handoff every single turn.
- Scripted **temptations** (`temptations.txt`) are injected at set iterations: attractive tangents
  that do not serve done-when and can eat the budget.
- **Headline metric is objective:** iterations-to-done-when (or pass@K), plus waste-file count.

Hypothesis: B reaches done-when in fewer iterations / higher pass@K than A and C, with fewer waste
files, because the externalized anchor re-orients each cold iteration. Worked task:
`tasks/release-prep-loop/`.

## Scenario battery (your five, re-tagged with executable done-when + one hostile)

| Task | Stress | done-when is | Lodestar expected |
|---|---|---|---|
| release-prep-loop | long-horizon + cold restarts + temptations | computed (`done_when.sh`) | **win** |
| requirement-change | goal mutates mid-run | computed (new target met, old not) | win |
| interrupt-barrage | repeated tangents | computed (waste files ≈ 0) + judged drift-recovery | win |
| compaction-continue | forced summary, then continue | computed (next action correct) | win |
| subagent-handoff | fresh-context subagent continues | computed + judged handoff quality | win |
| quick-fix (**hostile**) | one-line bug, clear goal, single shot | computed | **tie or lose** (overhead) |

## Metrics

**Objective (computed, no LLM):**
`done_when_passed`, `iterations_to_done`, `waste_files` (files touched outside the relevant set),
`unrecovered_drift` (tangent artifacts present AND done-when unmet), `decision_violation`
(output contradicts a planted prior decision — string/behavior check), `tokens`, `elapsed`,
`tool_calls`.

**Subjective (blinded 3-judge median, 0–3):**
`drift_recovery`, `decision_reuse`, `domain_consistency`, `handoff_quality`, `output_quality`.

**Within-B mechanistic check (diagnostic, NOT a cross-arm metric):** when a scripted temptation
fires, does B's `anchor.md` drift-check / return-stack actually register it? This validates the
*mechanism* is live, separate from the outcome comparison — kept apart to avoid circularity.

## Statistics & pre-registration
- `n ≥ 5` seeds per (task × arm); report mean ± stdev, not single runs.
- Paired/blocked by task; report a paired sign test or bootstrap CI on the B−A and **B−C** deltas.
- **Pre-register** expected direction per task (the table above) *before* running. Log the rubric
  hash. No metric or task added after seeing results.

## Falsification — what would mean "not supported"
- B ≈ A on `drift_recovery` / `iterations_to_done` → the anchor isn't changing behavior.
- B ≈ C → value is "reminding," not the mechanism.
- On long tasks, B's extra `tokens`/`elapsed` is **not** repaid by higher `pass@K` → net cost.
- B loses on the hostile task by more than a small margin → overhead is worse than predicted.

## Automation
`run.sh` drives every `(task × arm × seed × iteration)` cell headlessly via a pluggable
`--agent` command (`claude -p …`, `codex exec …`, or `mock` for harness self-test), resets context
per iteration, runs `done_when.sh`, and appends one JSON line per run to `results.jsonl`. The mock
path lets the harness itself be smoke-tested deterministically with no API spend. The LLM-judge
pass (`judge.md`) is a second, also-headless step over the blinded transcripts.

## Packaged tasks

### `release-prep-loop`
Long-horizon release prep with cold restarts and temptations; done-when is a code-state check.

### `su-dongpo` — content-development long-horizon test
Expand a Su Shi essay **chapter by chapter** toward a single measurable thesis ("Su Shi metabolized
exile through transcendent equanimity"), with **content-triggered tangent questions** planted in the
source. Each chapter is written in a fresh context (cold restart); the three arms differ only in what
orientation is re-injected each chapter. The goal/thesis lives in `goal.md` (experimenter ground
truth) and is deliberately **kept out of** `source/苏东坡.md`, so orientation can only come from each
arm's apparatus — that is what the experiment isolates. Objective scoring (`done_when.sh`): chapter
count, per-chapter length, thesis-tie ratio, required-coverage %, tangent avoidance.

### `gap-consolidation` — representation stress test
Tests memory representation directly rather than the A/B/C orientation mechanism: flat truncate vs
flat summarize vs an agent-maintained GAP ledger. It forces two memory consolidations, a reopened
decision, and a moving core goal. The pilot result is recorded in [`FINDINGS.md`](FINDINGS.md):
flat summaries beat the agent-maintained ledger even in the ledger's intended regime. This does not
rule out deterministic tool-maintained structure; that remains a separate, untested system.

### `release-alignment-gauntlet` — realistic release-context stress test
Creates a deliberately inconsistent Lodestar repo fixture and scores whether an agent aligns README,
Chinese README, CHANGELOG, skill protocol, templates, hooks, plugin metadata, and release checks
without version drift or overclaiming. The first executable version includes deterministic smoke
agents:

```bash
bash evals/tasks/release-alignment-gauntlet/run_smoke.sh --agent noop --seeds 1 --run-tests
bash evals/tasks/release-alignment-gauntlet/run_smoke.sh --agent oracle --seeds 1 --run-tests
```

`noop` should fail and `oracle` should pass. Those runs validate the fixture and scorer; they are
not evidence about an LLM arm. To run a small real-agent pilot:

```bash
bash evals/tasks/release-alignment-gauntlet/run_agent.sh --arms A,B,C,D,E --seed-start 1 --seeds 1 --run-tests
```

This performs eight fresh `codex exec` invocations per `(arm, seed)`. It is real agent behavior, but
still below the preregistered n>=5/n>=10 threshold. Use `--seed-start 2` or higher when extending a
pilot without rerunning earlier seed fixtures. The default runner uses a temporary isolated
`HOME`/`CODEX_HOME` containing only `auth.json`, so user-level Codex config, memories, plugins,
skills, and trusted-project state do not leak into the benchmark. On systems without
`timeout`/`gtimeout`, it uses a bash watchdog so `--timeout-seconds` still bounds stalled turns.

## How to repeat the experiment

Two run paths, same fixtures and same scorer:

1. **Portable / cross-harness (`run.sh`):** drives `(arm × seed × iteration)` headlessly via a
   pluggable `--agent` (`claude -p …`, `codex exec …`, or `mock`). Self-testable with `--agent mock`.
   `done_when.sh` is the canonical scorer; results land in `results.jsonl`.
2. **In-session (Claude Code Workflow):** `lodestar-su-dongpo-eval` fans out A/B/C × chapters with
   real subagents (one per chapter = one cold restart) and a blind judge per arm. The objective
   scorer in the workflow mirrors `done_when.sh`; keep the two in sync.

Either way: run `n ≥ 5` seeds, report mean ± stdev of the **B−A** and **B−C** deltas, and read the
result against the pre-registered directions and falsification lines above. A green run that doesn't
beat the placebo arm (C) is a real, publishable negative result — not a failure to report.

## File map
```
evals/
├── README.md                     # this protocol
├── FINDINGS.md                   # pilot results and caveats
├── rubric.json                   # machine-readable metric definitions + pre-registered directions
├── judge.md                      # blinded LLM-judge prompt (subjective metrics)
├── run.sh                        # headless A/B/C × seed × iteration runner (mock-testable)
└── tasks/
    ├── release-prep-loop/
    │   ├── task.md               # instructions handed to the agent each iteration
    │   ├── done_when.sh          # executable objective done-when + waste detector
    │   └── temptations.txt       # scripted tangents, keyed by iteration
    ├── su-dongpo/
    │   ├── task.md               # chapter-by-chapter expansion instructions
    │   ├── goal.md               # experimenter ground truth: thesis + measurable done-when
    │   ├── questions.txt         # per-chapter content-triggered questions (goal + tangent)
    │   ├── done_when.sh          # objective scorer (chapters/length/thesis-tie/coverage/tangent)
    │   └── source/苏东坡.md       # pure material skeleton — NO thesis (orientation comes from the arm)
    ├── gap-consolidation/
    │   └── spec.md               # F/S/G representation stress test used by Run 8
    └── release-alignment-gauntlet/
        ├── spec.md               # realistic release-context task
        ├── ground_truth.json     # machine-readable release-alignment contract
        ├── seed_fixture.sh       # creates deliberately inconsistent repo fixtures
        ├── score.sh              # objective scorer
        ├── run_smoke.sh          # deterministic noop/oracle runner
        ├── run_agent.sh          # real Codex cold-start pilot runner
        ├── judge.md              # blind judge prompt
        └── turns/                # cold-start turn prompts
```

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
- **A — bare:** `AGENTS.md` + a plain `TODO.md`.
- **B — Lodestar:** flat `.lodestar/` state plus an explicit state-update instruction.
- **C — reminder baseline:** `FOCUS.md` carrying the same initial goal information without a
  structured state-update protocol.

The portable `run.sh` injects B and C through the **same driver path once per cold iteration**.
It does not install native hooks: this tests restart orientation, not lifecycle-hook integration.
Actual orientation, byte counts, full prompts, stdout/stderr, and exit codes are saved per turn.
These arms are **not token-matched**; byte counts are diagnostic and are not token counts. Host
configuration also needs isolation for a real run. B>C alone cannot isolate structure from dose or
maintenance effort. A future mechanism experiment must match token exposure at the same lifecycle
points and verify real hook delivery. The three-arm design below remains the intended experiment,
not a claim that the portable smoke runner implements every control.

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
`run.sh` currently implements `release-prep-loop` and drives every `(arm × seed × iteration)` cell headlessly via a pluggable
`--agent` command (`claude -p …`, `codex exec …`, or `mock` for harness self-test), resets context
per iteration, runs `done_when.sh`, and appends one JSON line per run to `results.jsonl`. The mock
path lets the harness itself be smoke-tested deterministically with no API spend. A blinded LLM-judge pass is described in `judge.md` but is not executed by this runner.

## Packaged tasks

### `release-prep-loop`
Long-horizon release prep with cold restarts and temptations; done-when is a code-state check.

### `su-dongpo` — content-development long-horizon test
Expand a Su Shi essay **chapter by chapter** toward a single measurable thesis ("Su Shi metabolized
exile through transcendent equanimity"), with **content-triggered tangent questions** planted in the
source. Each chapter is written in a fresh context (cold restart); the three arms differ only in what
orientation is re-injected each chapter. This task has no portable runner in `run.sh`; its material is used by the in-session workflow.
The goal/thesis lives in `goal.md` (experimenter ground
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

Arm E is an **agent-maintained JSON ledger with syntax validation**. The validator only runs
`jq empty`; it does not update entries or maintain their meaning. It cannot test deterministic
tool-maintained memory. Historical E labels are corrected in the artifact notes.

This performs eight fresh `codex exec` invocations per `(arm, seed)`. It is real agent behavior, but
still below the preregistered n>=5/n>=10 threshold. Use `--seed-start 2` or higher when extending a
pilot without rerunning earlier seed fixtures. The default runner uses a temporary isolated
`HOME`/`CODEX_HOME` containing only `auth.json`, so user-level Codex config, memories, plugins,
skills, and trusted-project state do not leak into the benchmark. On systems without
`timeout`/`gtimeout`, it uses a bash watchdog so `--timeout-seconds` still bounds stalled turns.

### `planning-conversation` — planning-partner behavior across cold restarts
Eight cold-start turns plan a fictional product (Orbit) in a separate docs project: ideas raised in
passing, a planted first-principles conflict (plaintext API keys in the cloud despite a "data stays
on the machine" constraint), a user override, an unrelated follow-up, an explicit goal change, and a
spec request for an agent that cannot see the conversation. Arms: A bare, B Lodestar planning
workspace (hook context delivered by the portable driver), C free-form notes placebo.

```bash
bash evals/tasks/planning-conversation/run_smoke.sh      # scorer must separate good/bad fixtures
bash evals/tasks/planning-conversation/run_agent.sh --agent-cmd 'claude -p --permission-mode acceptEdits' --seeds 5
```

The scorer is representation-agnostic and does not award points for Lodestar-specific files
(`dashboard_present` and `doctor_passed` are reported only). No live arms have been run yet; the
smoke fixtures validate the scorer, not the planning layer.

## How to repeat the experiment

Run paths and their current scope:

1. **Portable / cross-harness (`run.sh`, release-prep-loop only):** drives `(arm × seed × iteration)` headlessly via a
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
    ├── release-alignment-gauntlet/
    │   ├── spec.md               # realistic release-context task
    │   ├── ground_truth.json     # machine-readable release-alignment contract
    │   ├── seed_fixture.sh       # creates deliberately inconsistent repo fixtures
    │   ├── score.sh              # objective scorer
    │   ├── run_smoke.sh          # deterministic noop/oracle runner
    │   ├── run_agent.sh          # real Codex cold-start pilot runner
    │   ├── judge.md              # blind judge prompt
    │   └── turns/                # cold-start turn prompts
    └── planning-conversation/
        ├── spec.md               # planning-partner task, arms, metrics
        ├── ground_truth.json     # idea patterns, planted conflict, spec contract
        ├── score.sh              # representation-agnostic objective scorer
        ├── run_smoke.sh          # good/bad fixture check for the scorer
        ├── run_agent.sh          # any-agent cold-start driver (A/B/C)
        ├── judge.md              # blind judge rubric
        ├── fixtures/             # good/ and bad/ projects with transcripts
        └── turns/                # the eight user turns
```

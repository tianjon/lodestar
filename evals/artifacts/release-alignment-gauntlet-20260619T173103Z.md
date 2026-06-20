# Release Alignment Gauntlet Pilot — 20260619T173103Z

- Date: 2026-06-19 UTC
- Base commit: `66887e6`
- Task: `evals/tasks/release-alignment-gauntlet`
- Runner: `run_agent.sh`
- Agent: `codex exec`, fresh context per turn
- Arms: A bare, B flat Lodestar, C placebo focus, D agent GAP ledger, E tool GAP ledger
- Seeds: 1 per arm
- Turns: 8 per run
- Raw artifacts: `evals/.runs/release-alignment-gauntlet-real-20260619T173103Z/`

## Command

```bash
bash evals/tasks/release-alignment-gauntlet/run_agent.sh \
  --arms A,B,C,D,E \
  --seeds 1 \
  --out /Users/yr/ai/lodestar/evals/.runs/release-alignment-gauntlet-real-20260619T173103Z \
  --timeout-seconds 900 \
  --run-tests
```

The runner disabled Chronicle, memories, plugins, apps, and multi-agent features for each Codex
turn, and used low reasoning effort to reduce environment noise and runtime cost.

## Objective Results

Initial scorer output:

| Arm | Score | Pass |
|---|---:|---:|
| A bare | 76 | 0/1 |
| B flat Lodestar | 84 | 0/1 |
| C placebo focus | 84 | 0/1 |
| D agent GAP ledger | 76 | 0/1 |
| E tool GAP ledger | 76 | 0/1 |

During analysis, the scorer required two post-run repairs:

1. v2 stopped overcounting negated caveats such as "not statistically proven" and made bilingual
   consistency semantic rather than exact-phrase-only.
2. v3 corrected the scope gate: the task explicitly names "hooks" as a release wording surface, so
   all hook scripts are allowed scope. The required seeded hook surfaces remain `hooks/pre-compact`
   and `hooks/lib.sh`.

The raw run was not rerun; the same final repos were rescored with
`release-alignment-gauntlet-score-v3`:

| Arm | v3 score | v3 pass | Main remaining failure |
|---|---:|---:|---|
| A bare | 84 | 0/1 | missed 3 required surfaces; retained 3 default-ledger claims |
| B flat Lodestar | 100 | 1/1 | none |
| C placebo focus | 100 | 1/1 | none |
| D agent GAP ledger | 76 | 0/1 | overclaim; missing tool-ledger caveat; bilingual inconsistency |
| E tool GAP ledger | 76 | 0/1 | missed 1 required surface; retained 1 default-ledger claim; overclaim |

## Interpretation

This is an anecdotal pilot, not statistical evidence. With one seed:

- B and C tied after scorer v3 repair: the flat Lodestar arm did not beat the equal-information
  placebo reminder in this run.
- Both B and C completed the substantive alignment and passed the objective done-when. This supports
  "orientation text helped versus bare" in this seed, but not "Lodestar structure beat placebo."
- D did not help; the heavy agent-maintained GAP ledger arm scored with the bare arm after rescoring.
- E exercised the tool-maintained ledger successfully, but it did not produce a passing result in
  this single run.

## Validity Notes

- This is below the preregistered `n >= 5` threshold and far below `n >= 10`.
- Blind judging has not been run.
- The scorer itself required post-run repairs, so report both initial and v3 results when discussing
  this pilot.
- The v3 scope repair is justified by the written task, but it is still a post-run scorer change;
  future claims need more seeds run under the fixed scorer.
- Deterministic smoke after the scorer repair still passed: `noop` failed and `oracle` passed.

## Verification

```bash
bash -n evals/tasks/release-alignment-gauntlet/score.sh evals/tasks/release-alignment-gauntlet/run_agent.sh evals/tasks/release-alignment-gauntlet/run_smoke.sh
bash tests/lodestar_cli_test.sh
bash evals/run.sh --agent mock --seeds 1 --iters 2 --out /tmp/lodestar-eval-mock-v3
bash evals/tasks/release-alignment-gauntlet/run_smoke.sh --agent noop --seeds 1 --out /tmp/lodestar-release-gauntlet-noop-v3 --run-tests
bash evals/tasks/release-alignment-gauntlet/run_smoke.sh --agent oracle --seeds 1 --out /tmp/lodestar-release-gauntlet-oracle-v3 --run-tests
git diff --check
```

All commands exited 0. The mock eval intentionally produced `pass@2 = 0/1` for A/B/C; it is a
plumbing check, not a solver.

Follow-up: `release-alignment-gauntlet-seed2-core-20260620T053452Z.md` records an isolated A/B/C
seed 2 run and runner hardening discovered after this pilot.

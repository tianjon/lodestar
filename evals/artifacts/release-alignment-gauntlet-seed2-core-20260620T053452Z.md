# Release Alignment Gauntlet Core Follow-up — Seed 2

- Date: 2026-06-20 UTC
- Base fixture commit: `66887e6`
- Task: `evals/tasks/release-alignment-gauntlet`
- Scorer: `release-alignment-gauntlet-score-v3`
- Arms included here: A bare, B flat Lodestar, C placebo focus
- Seed: 2

## Valid Runs

Seed 2 was split across two raw run directories because the runner was hardened during execution:

| Arm | Raw run | Run id | Isolation | Failed turns |
|---|---|---|---|---:|
| A bare | `evals/.runs/release-alignment-gauntlet-real-abc-seed2-clean/` | `20260620T025243Z` | temporary `HOME`/`CODEX_HOME`; clean stderr except analytics warnings | 0 |
| B flat Lodestar | `evals/.runs/release-alignment-gauntlet-real-bc-seed2-isolated-v2/` | `20260620T053452Z` | temporary `HOME`/`CODEX_HOME`; clean stderr except analytics warnings | 0 |
| C placebo focus | `evals/.runs/release-alignment-gauntlet-real-bc-seed2-isolated-v2/` | `20260620T053452Z` | temporary `HOME`/`CODEX_HOME`; clean stderr except analytics warnings | 0 |

## Invalidated Attempts

These raw directories are retained for audit but should not be counted as experiment results:

| Raw run | Reason invalidated |
|---|---|
| `evals/.runs/release-alignment-gauntlet-real-abc-seed2/` | Nested Codex inherited user-level skills; stderr showed global Lodestar skill/YAML noise. |
| `evals/.runs/release-alignment-gauntlet-real-abc-seed2-clean/` B/C portion | B turn 3 entered a long websocket retry; the macOS fallback did not enforce `--timeout-seconds` before the watchdog fix. A had already completed cleanly and is retained. |
| `evals/.runs/release-alignment-gauntlet-real-bc-seed2-isolated/` | Bash timeout fallback ran Codex in the background without preserving stdin; all turns failed with `No prompt provided via stdin`. |

## Objective Results

| Arm | Score | Pass | Main failure |
|---|---:|---:|---|
| A bare | 100 | 0/1 | scope creep: `skills/lodestar/references/anti-drift.md`, `skills/lodestar/references/ontology.md` |
| B flat Lodestar | 100 | 1/1 | none |
| C placebo focus | 84 | 0/1 | missed 3 required surfaces; retained 3 default-ledger claims; scope creep: `docs/TASKS.md` |

## Cumulative Core Signal

This combines the seed 1 v3 rescoring and the valid seed 2 core follow-up:

| Arm | Seed 1 v3 | Seed 2 | Pass count |
|---|---:|---:|---:|
| A bare | 0/1 | 0/1 | 0/2 |
| B flat Lodestar | 1/1 | 1/1 | 2/2 |
| C placebo focus | 1/1 | 0/1 | 1/2 |

Treat this as directional only. Seed 1 was rescored after the run and was not isolated from
user-level skill scanning; seed 2 was isolated, but still only one additional seed. The honest
current read is:

- Flat Lodestar is ahead of bare on the two observed core seeds.
- Flat Lodestar beat placebo on seed 2, but the sample is still too small to claim a mechanism win.
- Scope control is doing real work: A reached all scalar checks but failed because it edited beyond
  the release-alignment surface; C failed both coverage and scope.

## Runner Repairs Made During Follow-up

- Added `--seed-start` so later samples can continue without rerunning earlier seeds.
- Added temporary `HOME`/`CODEX_HOME` isolation with only `auth.json`.
- Added a bash watchdog fallback for platforms without `timeout`/`gtimeout`.
- Fixed the watchdog path to preserve prompt stdin when the Codex process runs in the background.

## Next Valid Run

Run at least seeds 3-5 for A/B/C under the fixed runner before discussing B-vs-C as anything more
than a suggestive pattern. A full release-grade claim still needs the preregistered threshold, blind
judge pass, and either a rerun of D/E or an explicit decision to narrow the claim to the core A/B/C
comparison.

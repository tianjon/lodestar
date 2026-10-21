# Eval Findings (pilot — directional)

Status: **n=2–3 per arm, pilot scale.** Directional, not significant. Eight runs.

## Headline

1. **Persisting the relevant information across resets is the real value.** Directionally supported in the pilots where the bare
   agent loses the info (runs 2, 5, 6, 7).
2. **A flat notes representation beats a structured one — in BOTH regimes now, including memory
   consolidation.** Run 8 finally tested the regime a GAP ledger is designed for (two forced merges +
   a status reopen + a moving core goal). The GAP ledger came **last**; flat-summarize came **first**.
3. **Mechanism (consistent across runs 5/7/8):** a structured, agent-maintained memory (tree, GAP
   ledger) is **fragile to maintain** — re-rendering/compressing it repeatedly garbles ids and drops
   entries. A flat list/summary is robust. In run 8 the flat arms kept the old-open branch **every
   time** (even under a recency-drop rule), while the GAP ledger — under an explicit keep-open rule —
   **lost it 2 of 3 times** and held the core goal worst.

## Run 8 — gap-consolidation HARD (the test you asked for)
| arm | open_recall | recalled_old_open | caught_reopen | false_open | core_goal_held |
|---|---|---|---|---|---|
| F flat-truncate | 2.33 | 1.00 | 0.33 | 1.00 | 3.00 |
| **S flat-summarize** | **3.00** | **1.00** | **0.67** | 0.67 | **3.00** |
| G GAP-ledger | **1.33** | **0.33** | 0.33 | 0.33* | **1.67** |

\* G's low false_open is an artifact of under-recall — it surfaced so few branches it had fewer chances
to be wrong. It did not preserve more; it preserved less.

**Verdict:** even in its home regime, the agent-maintained GAP ledger does **not** earn its place. The
hypothesis "tracking branch-vs-core-goal gaps pays off at memory merge" was reasonable and worth
testing (it was genuinely untested before run 8) — but the pilot argues against making this representation the default; broader confirmation is pending.

## Important caveat (same rigor we applied to run 7)
Run 8 tests an **agent-maintained** GAP ledger, and its failure is driven by **maintenance fragility of
structure**, not by the GAP *concept* in the abstract. A GAP ledger maintained by a **deterministic tool
/ hook** (not the LLM) is a different, untested thing and could behave differently. But for the realistic
Lodestar design — where the agent maintains `.lodestar/` files — the evidence across runs 5/7/8 is now
directionally consistent: **these tested structured representations lost.**

## Runs
| Run | Task | Regime | Verdict |
|---|---|---|---|
| 1 | su-dongpo base | short, no-merge | Null (ceiling). → T8. |
| 2 | goal-shift | short, no-merge | Persistence supported. B≈C. |
| 3 | constraints (counter) | short, no-merge | Invalid metric. Discarded. |
| 4 | constraints (judge) | short, no-merge | Null (ceiling). |
| 5 | descent-drift | driver-maintained tree | D≫flat — but tree was perfectly maintained; unreplicated. |
| 6 | rabbit-hole | single finale, tiny | B=C=D. |
| 7 | multitask-chat | agent-maintained, no-merge | Flat ≫ tree (regeneration fragility). |
| 8 | **gap-consolidation HARD** | **2 forced merges + reopen + moving goal** | **Flat ≫ GAP ledger.** Structure loses even at consolidation. |

## Honest standing
- **Directionally supported:** persistence helped; a **flat** representation performed best in these no-merge
  and the consolidation regimes (for agent-maintained memory).
- **Directionally refuted as a default (for the tested agent-maintained representations):** the GAP ledger / structured schema earns its place — it
  doesn't, even in its designed regime.
- **Still untested:** a **tool/hook-maintained** structured GAP ledger (deterministic, not LLM-rendered).
  That is the only remaining door for structure, and it is a different system from what Lodestar ships.
- **So:** stripping the agent-maintained GAP engine is now **evidence-supported** (8 runs), pending an
  n≥5 confirmation. If structure is to be revived, it must be **tool-maintained**, and tested as such.

## Open debt
- Residual goal-restatement preamble (T10). Run 6 harness artifact (un-anchored agent leaked repo content).

## Review correction (2026-10-21)

These pilots support the current engineering default, not a universal claim that structure loses.
The later release-alignment follow-up reports B 2/2 and C 1/2, with contamination/rescoring caveats;
see `artifacts/release-alignment-gauntlet-seed2-core-20260620T053452Z.md`.
The historical gauntlet E arm was mislabeled tool-maintained: its helper only validated JSON syntax.
It remains agent-maintained memory, so deterministic maintenance is still untested. The portable
runner's B/C exposure mismatch has now been repaired, but old runs are not retroactively validated.
The updated runner records exposure and does not claim token matching or native-hook validation.

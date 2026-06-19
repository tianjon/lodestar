# Eval Findings (pilot — directional, but now converging)

Status: **n=2–3 per arm, pilot scale.** Directional, not significant — but seven runs now point the
same way, and the decisive run (#7) has a clear mechanism, not just a number.

## Headline (after 7 runs)

1. **Persisting the relevant information across resets is Lodestar's real value.** Confirmed wherever
   the bare agent actually loses the info (runs 2, 5, 6, 7).
2. **Among memory representations, a flat append-only list is best — and *more* structure is actively
   worse.** In the hardest, most realistic test (run 7: 3 interleaved threads, agent maintains its own
   notes across 9 cold-restart turns), **flat (B) scored a perfect 3.0 / 100% key recall; the tree (D)
   scored 1.5 — worse than an unstructured blob (C, 1.83) and barely above bare (A, 1.0).**
3. **Mechanism:** maintaining a *tree* across many updates is costly — the agent re-renders it each
   turn and **drops/garbles entries** (D literally answered "my notes don't record that" and lost the
   Postgres-only constraint). A flat list is append-only and lossless, so it retains everything.

This **resolves the H1/H2 question and reverses the descent-drift hint:** descent-drift's tree win
came from a **driver-maintained** (perfect) tree. The moment a *real agent* must maintain the tree —
the faithful Lodestar condition — the maintenance cost backfires and the tree loses.

## Runs

| Run | Task | Verdict |
|---|---|---|
| 1 | su-dongpo base | Null (ceiling). Surfaced anchor leak → T8. |
| 2 | su-dongpo goal-shift | **Persistence supported.** Bare reverts; re-injection holds. B≈C. |
| 3 | constraints (counter) | Invalid metric. Discarded. |
| 4 | constraints (blind judge) | Null (ceiling). |
| 5 | descent-drift (driver-maintained tree) | D≫flat — but tree was perfectly maintained by the driver; unreplicated. |
| 6 | rabbit-hole (single finale, 5 notes) | B=C=D. Structure irrelevant on a tiny note-set. |
| 7 | **multitask-chat (agent-maintained notes, 3 threads, 9 turns)** | **Flat (B) ≫ tree (D); tree HURTS.** Decisive. |

## What is supported
- **Persistence of relevant info across resets** — the validated core.
- **Flat, append-only notes as the representation** — empirically best (run 7), because it is cheap to
  maintain losslessly.
- **T8 silent-anchor fix** (runs 3, 4).

## What is refuted
- **Upgrading memory to a tree.** Not just "no benefit" — **net harmful** when the agent maintains it
  (run 7). The honest answer to "do we need a tree?" is **no.**
- By extension, **"more structure = better" is false here.** This raises a concrete, testable product
  question: is Lodestar's `full` profile (more structure) *worse* than `minimal`? Run 7's mechanism
  predicts yes. Worth a direct `minimal` vs `full` eval before recommending `full` for anything.

## Caveats
- n=2 in run 7 (consistent across both seeds, with a clear mechanism, but small).
- "Agent maintains its own notes" makes this a test of *templates for agent-maintained memory*
  (the realistic Lodestar case), not abstract data structures.
- Replicate at n≥5 and on a second multi-thread domain to firm it up.

## Product implications (evidence-backed)
- **Keep the anchor/notes flat and append-only.** Do **not** add tree/nested structure to the memory
  files. This *validates* Lodestar's minimal-by-default design and argues against its heavier schema.
- Consider making `minimal` the only recommended profile pending a `minimal`-vs-`full` eval.

## Open measurement debt
- Residual goal-restatement preamble (T10).
- Run 6 harness artifact: an un-anchored agent leaked unrelated repo content into its answer.

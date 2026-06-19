# Variant: goal changes mid-run (the discriminating manipulation)

The base `su-dongpo` task has a **ceiling effect** — a strong model holds a single fixed thesis even
without orientation, so all arms pass and the experiment can't discriminate. This variant fixes that
by testing the regime where Lodestar's persistence claim should actually matter: **the goal changes
partway through, after a cold restart.**

## The manipulation
- **Chapters 1–3** pursue **Thesis-1**: *苏轼以旷达超然消化贬谪*
  (keywords: 旷达 / 超然 / 豁达 / 随遇而安 / 从容 / 乐观).
- **At chapter 4 the goal changes to Thesis-2**: *苏轼始终未改用世济民的政治理想*
  (keywords: 用世 / 济世 / 济苍生 / 政治理想 / 兼济 / 经世 / 担当 / 直言 / 为民 / 致君).
- The two theses are in genuine tension (transcendence vs. worldly engagement), so an agent that
  fails to notice the change keeps writing Thesis-1.

## How each arm receives the change (cold restart every chapter)
- **A (bare):** told the new goal **once** at chapter 4; chapters 5–6 run in fresh context with only
  static notes + the document so far (which is Thesis-1-heavy). A should regress to Thesis-1.
- **B (Lodestar):** the new goal is written into `anchor.md` and **re-injected every chapter** from 4
  on. B should adopt Thesis-2 and hold it.
- **C (placebo):** the new goal text is re-injected every chapter (same volume, no structure). C
  should also adopt it — so **B≈C tests structure; A vs (B,C) tests persistence across restarts.**

## What is measured (objective)
- `late_new_thesis_tie`: fraction of chapters 4–6 that adopt Thesis-2 keywords (high = adapted).
- `late_old_only`: fraction of chapters 4–6 that stay Thesis-1-only (high = drift / missed the change).
- `adopted_change`: `late_new_thesis_tie ≥ 0.66`.
- `scaffold_leaks`: count of apparatus tokens (Lodestar / 锚点 / 朝向 / FOCUS …) in the prose — this
  doubles as a regression check for the T8 "silent anchor" fix; it should be **0**.

## Expected (pre-registered)
`B ≈ C` adopt the change; `A` largely fails to. If A keeps up via document recency alone, that is an
honest finding that the written artifact suffices and the anchor adds little — report it as such.

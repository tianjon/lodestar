# Eval Findings (pilot — directional)

Status: **n=2–3 per arm, pilot scale.** Directional signals, not significance. We report negative and
null results as readily as positive ones — that is the point. The headline below is honest and narrow.

## Headline

Across four pilots, **the only manipulation that ever discriminated between arms was a mid-run goal
change.** Every static task hit a ceiling: a strong model writing a focused piece holds a fixed goal
and honors reasonable constraints *by default*, so no arm fails and nothing is measured.

So Lodestar's demonstrable value is **narrow and specific**:

- ✅ **Persisting information that *changes* across a context reset** — a goal that shifted, a decision
  made mid-stream. The bare arm cannot know it changed after the conversation is gone; re-injected
  orientation holds it.
- ❌ Not "help the model stay on a fixed goal" — the model does that unaided.
- ❌ Not "honor static constraints" — the model does that unaided.
- ❓ **Structured schema vs plain reminder (B vs C): never shown.** B≈C when the goal changed;
  all-perfect (no separation) on the constraints task. Whenever orientation is re-injected, an
  unstructured reminder does as well as the labeled anchor.

## Runs

| Run | Task | Question | Result |
|---|---|---|---|
| 1 | `su-dongpo` base | does orientation help a long essay? | **Null (ceiling).** All arms held the fixed thesis. Surfaced anchor text leaking into B's prose → fix T8. |
| 2 | `su-dongpo` goal-shift | does re-injection survive a mid-run goal change? | **Discriminates. Persistence supported (directionally):** after the goal changed at ch4, bare arm A adopted it for one chapter then reverted (0/2); B and C held it (2/2). **B≈C.** |
| 3 | `su-dongpo` constraints (counter) | does a structured anchor hold constraints better? | **Invalid metric.** Counting `御史台`/`苏辙` conflated violation with compliance + B's own boundary vocabulary → discarded. T8 confirmed (`leak_raw`=0). |
| 4 | `su-dongpo` constraints (T9, blind judge) | same, measured properly | **Null (ceiling).** Blind judge: all arms 3/3, zero real violations — confirming run 3's counts were artifacts. T8 re-confirmed. Residual: goal sentence still leaks as a process preamble. |

## What is supported
- **Cross-restart persistence of *changed* information** (run 2) — Lodestar's core value, in the one
  regime where the bare arm genuinely fails.
- **T8 silent-anchor fix** (runs 3, 4) — apparatus markers no longer appear in deliverables.

## What is NOT supported / still open
- **Structured schema > plain reminder (B > C).** Never demonstrated. Honest default: the value is
  hooks + a minimal re-injected goal; `minimal` profile is the right default; the heavy schema is
  unproven.
- A structure advantage, if it exists, would only appear when *many* things change/accumulate across
  resets so a flat reminder gets diluted — an experiment not yet run.

## Measurement bugs found (the recurring lesson: green ≠ measured)
1. **Title pollution** — source title `素材骨架` used as essay title tripped the leak scan. Fixed.
2. **Cleaner masking** — `cleanProse` stripped leaked lines before counting them. Fixed.
3. **Boundary-as-occurrence** — counting forbidden terms scored *compliance* ("此处不展开御史台") as a
   violation. Replaced by a blind judge (T9) that distinguishes developed-topic from passing-mention.
4. **Residual soft leak (open, T10)** — apparatus labels are gone, but expansion agents still emit
   process meta-text and restate the goal as a preamble ("这是我把握的方向,我直接写正文").

## Next (optional)
- Strengthen the silent instruction to suppress goal-restatement preambles (T10).
- If the structure question is worth chasing: a task where *many* constraints/goals evolve across
  resets, so a flat reminder dilutes and a structured anchor might separate. Otherwise the honest
  conclusion stands: **persistence is the value; minimal + hooks is the core; the schema is unproven.**

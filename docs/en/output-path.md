# How Lodestar Shapes Output

## Recording is not the point; changing the next action is

The only test that matters for an orientation system is whether stored state changes the next
answer, tool call, review, plan, or code edit. State that does not bend the next action is dead
weight — and dead weight that *looks* like diligence is worse than nothing.

## The orientation pipeline

```text
user directive
  -> domain parse        (terms, objects, boundaries)
  -> goal / done-when / boundary
  -> gap                 (requirement vs reality, with evidence + confidence)
  -> decision            (chosen path, alternatives, rationale)
  -> next action
  -> output frame        (the answer/edit is built to serve the goal)
  -> state update        (closes the loop; feeds the next cycle)
```

The loop closes deliberately: every cycle leaves the state a little clearer for the next one.

## Four surfaces where state reaches the output

1. `anchor.md` tells the agent **what the output must serve**.
2. `domain.md` gives the **vocabulary and boundaries** for interpreting the task.
3. `state.md` tells the agent **what is already true and which gaps remain**.
4. Hooks **inject this context before the agent acts**, so it is present at decision time rather
   than hoped-for.

## What good, Lodestar-aligned output looks like

- It answers the **active goal**, not merely the latest sentence.
- It challenges a stale active goal when enough evidence shows the real priority changed.
- It respects the **boundaries**.
- It speaks the project's **domain language**, not a generic template.
- It **reduces a named gap** or advances the next action.
- It leaves the next session with **better state** than it found.

## The anti-pattern it prevents

Confidently and competently answering the most recent sub-question while the actual goal goes
unserved. That is the silent slide expressed at the level of a single output — and the pipeline
above exists to catch it before the answer is written, not after.

The symmetric anti-pattern is confidently serving an old Anchor after the user's real goal has
changed. In that case, the right output is not automatic execution; it is a concise, evidence-backed
confirmation question about re-anchoring, branch priority, or parking the tangent.

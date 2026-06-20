# Why The Approach Is Effective

The throughline of the whole design is one sentence: **do not trust your own most recent thought
by default.** Everything below is a way of enforcing that.

## Externalized goal as a fixed setpoint

The goal usually lives only in the conversation, where recency erodes it. Lodestar moves it into a
small, stable, external artifact the agent re-reads before acting. A fixed setpoint is the
counterweight to recency bias — the model can compare the latest instruction against the active
goal and done-when instead of simply following the newest input.

The setpoint is not a prison. A stale anchor is another form of drift: the agent is still fluent,
but now it optimizes for yesterday's commitment instead of today's real objective. Lodestar should
therefore challenge the Anchor when there is enough evidence, ask for confirmation, and only then
rewrite the primary Goal or promote a branch priority.

## Cognitive grounding

Each design choice maps to an established idea. The names are pointers, not appeals to authority.

- **Complementary Learning Systems** — two tiers: fast episodic `log.md`, slow semantic
  `state.md`. Consolidation should preserve stable facts without forcing the agent to maintain a
  fragile structured ledger.
- **MemGPT / virtual context paging** — finite context is a memory hierarchy; size budgets trigger
  paging of cold detail to archive.
- **Generative Agents (recency × importance)** — retention is not pure recency; an old
  blueprint-level decision outranks a fresh trivial note, but repeated high-importance signals can
  outweigh an old Anchor.
- **Event Sourcing** — the log is an append-only event stream; current state is a materialized
  view derived from it. History is appended and re-projected, never quietly rewritten.
- **Perceptual Control Theory** — the four facets are one negative-feedback loop: setpoint,
  measurement, error.
- **Active Inference** — a GAP is prediction error between the intended and the feasible world;
  action exists to minimize it.
- **Mode switching** — exploration and execution are different regimes; `explore` protects
  sensemaking, `execute` resists drift, and the others sit between.
- **TRIZ + double-loop learning** — resolve a contradiction between requirement and practice by
  transcending it, and allow the system to question its own goal with evidence.

## Gap-driven and evidence-backed

Lodestar does not ask the agent to "remember more." It asks the agent to reduce a gap: requirement,
current reality or practice, evidence, and next action. Add confidence or a breakthrough path only
when that extra structure changes the next action. A practice claim must carry evidence or be marked
`evidence: missing`, so a fluent guess cannot masquerade as field practice.

## Hooks as enforcement — stated honestly

Protocols rely on the model remembering to follow them. Hooks reduce that reliance by injecting
context at lifecycle points. This is not perfect control: the model still does the judging. Hooks
raise the **floor** (the anchor is present when it matters) rather than the ceiling. That is a real
gain, and it is all that is claimed.

## The honest limits

Refusing unverifiable claims is itself part of the method, so the limits are stated plainly:

- The value is **conditional**. It is strongest where native harness features do not reach — across
  sessions, across compaction, across harnesses. On a short single-session task with a clear goal,
  the ceremony is overhead.
- The drift check is still **executed by the same model that drifts**; externalized triggering
  reduces, but does not erase, that self-reference.
- A **stale anchor misleads** with the authority of a written record. The agent must be able to
  detect evidence that the real goal changed, but it must surface that inference instead of
  silently rewriting the goal. The maintenance discipline — and, ahead, an executable `doctor` lint
  that turns the invariants (goal is one sentence, done-when is observable, every practice claim is
  evidenced) into checks — is what keeps the system honest rather than decorative.

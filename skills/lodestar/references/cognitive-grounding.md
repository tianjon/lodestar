# Cognitive Grounding

Why Lodestar is shaped the way it is. These names are design pointers, not appeals to authority.

- **Externalized setpoint**: `.lodestar/anchor.md` makes the active goal a stable object outside
  the model's recency-biased context stream.
- **Perceptual Control Theory**: Goal / Done-when are setpoints, State is perception, GAP is the
  error signal, and Action reduces the error.
- **Active Inference**: a GAP is prediction error between intended and current/feasible reality.
- **Mode switching**: exploration, clarification, decision, execution, and review are different
  cognitive regimes with different drift tolerance.
- **Evidence-backed reasoning**: Practice and State claims need sources or `evidence: missing`,
  so fluent guesses do not masquerade as field practice.
- **TRIZ + double-loop learning**: when Requirement and Practice conflict, look for a third path
  and be willing to challenge the goal itself with evidence.
- **Light DDD**: ubiquitous language, bounded contexts, core objects, capabilities, and scenarios
  help convert vague conversation into actionable domain structure without importing heavy
  enterprise architecture ceremony.
- **Event log + projection**: `.lodestar/log.md` records meaningful changes; `.lodestar/state.md`
  is the current projection. History should not be rewritten to look cleaner.
- **Anti-drift hooks**: lifecycle hooks are external reminders. They reduce reliance on the same
  model that may already be drifting, while remaining opt-in and reviewable.
- **Procedural scaffolding**: task skills provide methods for working; Lodestar provides the
  orientation substrate that decides whether those methods still serve the active goal.

The throughline: **do not trust the latest token by default.** Keep the goal as an explicit
external setpoint, keep domain language clear, cite evidence for reality claims, and act to close
a measured gap.

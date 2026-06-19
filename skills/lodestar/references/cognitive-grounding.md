# Cognitive Grounding

Why Lodestar is shaped the way it is. Each design choice maps to an established idea; the names
are pointers, not appeals to authority.

- **Complementary Learning Systems** (hippocampus / neocortex): two tiers — fast episodic
  `working.md`, slow semantic `consolidated.md`. Compaction is systems consolidation: replaying
  episodic detail into stable semantic structure.
- **MemGPT / virtual context paging**: finite context is a memory hierarchy. Size budgets
  trigger "paging" — consolidation moves cold detail out, keeps hot detail in.
- **Generative Agents** (recency × importance): retention is not pure recency. An old
  Blueprint-level decision (`imp ≥ 0.8`) outranks a fresh trivial note. Importance pins survival.
- **Event Sourcing**: the trend log is an append-only event stream; current-state is a
  materialized view derived from it. You never rewrite history, only append and re-project.
- **Perceptual Control Theory**: the four facets are one control loop. Blueprint/Goal are
  setpoints, State is the perception, GAP is the error you act to reduce — not four independent
  notes but a single negative-feedback system.
- **Active Inference**: a GAP is prediction error between the intended world and the feasible
  world. Action exists to minimize it.
- **Mode switching**: exploration and execution are different cognitive regimes. `explore`
  protects sensemaking; `clarify` turns ambiguity into a one-sentence goal; `decide` compares
  evidence and consequences; `execute` resists drift; `review` audits claims against outcomes.
- **Recency bias is the adversary** (the anti-drift loop): without an explicit anchor, an
  autoregressive agent over-weights the latest tokens and the goal decays. The pinned ANCHOR
  block is a fixed setpoint that the drift check repeatedly compares against — a deliberate
  counterweight to that bias.
- **Evidence-backed reasoning**: Practice claims and State claims should be supported by cited
  evidence and confidence. Otherwise the model's fluent guess can masquerade as field practice.
- **TRIZ + double-loop learning**: resolve a GAP by transcending the 要求/实践 contradiction
  rather than picking a side. Double-loop means the system may question its own goals — with
  evidence — not just optimize within them.
- **Procedural scaffolding**: task skills provide methods for working; Lodestar provides the
  orientation substrate that decides whether those methods still serve the active goal.

The throughline: **don't trust your own most recent thought by default.** Write requirements at
the source, keep the goal as an explicit external setpoint, cite evidence for practice claims,
and act to close a measured gap.

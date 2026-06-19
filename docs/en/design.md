# Design and Architecture

## A small portable core with harness-specific adapters

Lodestar is shaped as a domain core plus adapters (ports-and-adapters / anti-corruption layer).
The **core** is plain Markdown state and protocols that any agent can read and execute. The
**enforcement** — lifecycle hooks — is an adapter written once per harness (Claude Code, Codex).

The rule that keeps it portable: **the core never depends on the adapter.** If hooks are absent or
a runtime has no hook system, Lodestar degrades to a readable protocol, not a broken tool. Hooks
raise reliability; they are not a prerequisite.

## The four facets are one control loop

Blueprint and Goal are setpoints, State is the measurement, and the GAP is the error signal you
act to reduce. They are not four notes — they are a single negative-feedback loop. Everything
else in the design serves that loop.

## Project state

```text
.lodestar/
├── anchor.md   # smallest always-loaded control surface: mode / goal / done-when / boundaries / next action
├── domain.md   # light DDD map: language, bounded contexts, core objects, capabilities, scenarios
├── state.md    # current facts, open gaps, decisions, evidence summaries
├── log.md      # meaningful changes only; append-only; fast tier
└── archive/    # cold detail paged out of log.md
```

`log.md` is the fast, episodic tier; `state.md` is the slow, semantic tier. Detail flows from log
to state to archive as it cools. The anchor stays pinned and tiny so re-reading it is always cheap.

## Enforcement is the crux

A protocol that the drifting model must *remember* to run is weak. The same cognitive process that
drifts is being asked to catch the drift — a self-reference that fails precisely when it is needed
most. Hooks break the self-reference by triggering **externally**, independent of whether the model
remembers:

- **SessionStart** injects the anchor into context — not "please read it," but the text itself.
- **PreCompact** reminds the agent to persist the active goal, gaps, decisions, and next action
  *before* the lossy summary discards them.
- **PreToolUse** runs a drift check before a mutating action: does this advance done-when or a
  named gap?
- **SubagentStart / SubagentStop** carry the handoff into a fresh subagent and recapture its
  return.
- **Stop** nudges the agent to reflect changed goal / boundary / decision / gap back into state.

Hooks are **opt-in, reviewable, and never silently mutate project files.** They load context and
remind; they do not edit on your behalf.

## Minimal by default

Two profiles ship: `minimal` (default) and `full`. The schema is a discipline, not a ceremony —
expand structure only when it changes the next action. Filling fields with plausible-sounding
filler is the cargo-cult failure the minimal profile exists to prevent.

## Light DDD, explicitly bounded

Lodestar borrows Domain-Driven Design as a *cognitive* lens, not as a software-architecture
framework. It **adopts** ubiquitous language, bounded contexts, core objects, capabilities,
scenarios, and open questions — so the agent translates vague intent into a domain model and
produces project-fitting work instead of a generic template. It **rejects** tactical DDD:
`domain.md` implies no repositories, aggregate roots, or event sourcing in the codebase.

## Privacy

Project state is local-private by default. Secrets, credentials, personal data, and private URLs
are redacted before they are ever written; `.lodestar/` is git-ignored unless a team explicitly
opts into sharing reviewed, redacted state.

# Lodestar Ontology

Lodestar is an orientation system, not a general recall system. Its core domain is the
conversation-to-action loop: clarify the user's intent, name the current goal, compare that goal
with reality, and choose the next action that reduces the GAP.

## Bounded Contexts

| Context | Responsibility | Not responsible for |
|---|---|---|
| **Orientation Core** | Anchor, goal clarity, done-when, boundaries, mode, drift checks | Full-text recall or vector search |
| **Reasoning Ledger** | Directives, assumptions, evidence, decisions, open GAPs, actions | Hidden chain-of-thought |
| **Consolidation** | Projecting episodic entries into current state and trend log | Rewriting history to make it cleaner |
| **Skill Bridge** | Aligning task skills with the active goal before/after execution | Replacing task-specific methods |

## Core Objects

### Anchor

The always-loaded control surface at the top of `working.md`.

- `Mode`: one of `explore`, `clarify`, `decide`, `execute`, `review`.
- `Goal`: the one active objective right now, in one sentence.
- `DoneWhen`: observable acceptance criteria for the active goal.
- `Boundaries`: explicit out-of-scope constraints for this phase.
- `ReturnStack`: parked tangents and where to return after them.
- `DriftCheck`: last alignment check and result.

### Directive

A meaningful user instruction recorded at the source.

- Preserves the user's words except secrets/PII.
- Produces or updates one or more of: Goal, Boundary, GAP, Decision, Action.

### GAP

The error signal between desired state and current reality.

- `Requirement`: what the user wants, stated honestly.
- `Practice`: what current project facts, field practice, or literature suggest.
- `Evidence`: source-backed support for the practice claim or current-state claim.
- `Confidence`: `low`, `medium`, or `high`.
- `Breakthrough`: a third path when Requirement and Practice conflict.
- `NextAction`: the concrete action that should reduce the GAP.

### Evidence

A cited source for a claim. Evidence can be a file path, command output, commit, issue, web link,
MemPalace drawer, user quote, observed behavior, or explicit absence of evidence. Evidence must
include a confidence level when it supports a Practice or State claim.

### Decision

A choice that changes the path forward.

- `DEC-<date>-<n>` identifier.
- The choice made.
- Options considered.
- Evidence used.
- Consequences and follow-up actions.

### Action

A concrete next step chosen because it serves the active Goal and reduces a GAP.

### SkillRun

A task-specific workflow such as TDD, debugging, review, or superpowers. Lodestar does not replace
the task skill; it frames why the skill is being invoked and records what changed afterward.

## Relationships

```text
Blueprint sets long-term direction.
Goal realizes part of Blueprint.
DoneWhen verifies Goal.
Boundary constrains Goal.
Directive creates MemoryEntry.
MemoryEntry may open/update GAP.
GAP compares Requirement with Practice.
Evidence supports Practice, State, and Decision.
Decision resolves or narrows a GAP.
Action implements Decision or reduces GAP.
SkillRun executes Action using a task-specific method.
ConsolidationEvent projects MemoryEntries into CurrentState.
```

## Invariants

- The active Goal is one sentence. If it cannot be one sentence, the mode should be `clarify`.
- DoneWhen is observable. If it is not observable, the goal is not ready for `execute`.
- Every Practice claim inside a GAP needs Evidence or must be marked `evidence: missing`.
- Every Decision needs an identifier and a short rationale.
- Task skills may decide how to work, but Lodestar decides whether the work still serves the active Goal.
- External recall systems can supply Evidence; they do not replace the Anchor.

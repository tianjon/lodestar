# Lodestar Ontology

Lodestar is an orientation system, not a general recall system. Its core domain is the
conversation-to-action loop: clarify intent, name the current goal, model the relevant domain,
compare goal with reality, and choose the next action that reduces the GAP.

## Bounded Contexts

| Context | Responsibility | Not responsible for |
|---|---|---|
| **Orientation Core** | Anchor, goal clarity, done-when, boundaries, mode, next action, drift checks | Full-text recall or vector search |
| **Domain Modeler** | Ubiquitous language, bounded contexts, core objects, capabilities, scenarios, open questions | Heavy software DDD patterns unless needed by the project |
| **Reasoning Ledger** | Directives, assumptions, evidence, decisions, open GAPs, actions | Hidden chain-of-thought |
| **State Projection** | Current state, active GAPs, decision summary, evidence summary | Rewriting history to look cleaner |
| **Skill Bridge** | Aligning task skills and subagents with the active Goal/GAP | Replacing task-specific methods |

## Core Objects

### Anchor

The always-loaded control surface in `.lodestar/anchor.md`.

- `Mode`: one of `explore`, `clarify`, `decide`, `execute`, `review`.
- `Goal`: the one active objective right now, in one sentence.
- `DoneWhen`: observable acceptance criteria for the active goal.
- `Boundaries`: explicit out-of-scope constraints for this phase.
- `NextAction`: the next concrete action that serves the goal.
- `ReturnStack`: parked tangents and where to return after them.
- `DriftCheck`: last alignment check and result.

### Domain Map

The lightweight DDD surface in `.lodestar/domain.md`.

- `UbiquitousLanguage`: project terms with stable meanings and evidence.
- `BoundedContext`: responsibility boundary, inputs, outputs, and non-responsibilities.
- `CoreObject`: object the current goal acts on or changes.
- `Capability`: action the project/user/agent must be able to perform.
- `Scenario`: given/when/then example that clarifies behavior or done-when.
- `OpenQuestion`: ambiguity that affects the next action.

### Directive

A meaningful user instruction recorded only when it changes Goal, Done-when, Boundary, Domain,
State, Evidence, GAP, Decision, Action, or Handoff.

### GAP

The error signal between desired state and current reality.

- `Requirement`: what the user wants, stated honestly.
- `Practice`: current project fact, field practice, or literature claim.
- `Evidence`: source-backed support for the practice/current-state claim, or `evidence: missing`.
- `Confidence`: `low`, `medium`, or `high`.
- `Breakthrough`: a third path when Requirement and Practice conflict.
- `NextAction`: the concrete action that should reduce the GAP.

### Evidence

A cited source for a claim. Evidence can be a file path, command output, commit, issue, web link,
user quote, observed behavior, or explicit absence of evidence. Evidence must include confidence
when it supports a Practice or State claim.

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

A task-specific workflow such as TDD, debugging, review, or superpowers. Lodestar frames why the
skill is being invoked and records what changed afterward.

## Relationships

```text
Blueprint sets long-term direction.
Goal realizes part of Blueprint.
DoneWhen verifies Goal.
Boundary constrains Goal.
DomainMap gives Goal a shared language.
Directive may update Anchor, DomainMap, State, GAP, Decision, or Action.
GAP compares Requirement with Practice.
Evidence supports Practice, State, DomainMap, and Decision.
Decision resolves or narrows a GAP.
Action implements Decision or reduces GAP.
SkillRun executes Action using a task-specific method.
StateProjection summarizes log events into current State.
```

## Invariants

- The active Goal is one sentence. If it cannot be one sentence, Mode should be `clarify`.
- DoneWhen is observable. If it is not observable, the goal is not ready for `execute`.
- The Domain Map clarifies language and boundaries; it must not add ceremony for its own sake.
- Every Practice claim inside a GAP needs Evidence or must be marked `evidence: missing`.
- Every Decision needs an identifier and a short rationale.
- Task skills may decide how to work, but Lodestar decides whether the work still serves the active Goal.
- External recall systems can supply Evidence; they do not replace the Anchor.

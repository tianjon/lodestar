# Lodestar Ontology

Lodestar is an orientation system, not a general recall system. Its core domain is the
conversation-to-action loop: clarify intent, name the current goal, model the relevant domain,
compare goal with reality, and choose the next action that reduces the GAP.

First principle: hold the real goal, not merely the written goal. The Anchor is a working
commitment that resists recency drift; it is not a sacred record. If evidence shows the real goal
or priority may have changed, propose a re-anchor. Do not silently rewrite the Anchor.

## Bounded Contexts

| Context | Responsibility | Not responsible for |
|---|---|---|
| **Orientation Core** | Anchor, goal clarity, done-when, boundaries, mode, next action, drift checks | Full-text recall or vector search |
| **Domain Modeler** | Ubiquitous language, bounded contexts, core objects, capabilities, scenarios, open questions | Heavy software DDD patterns unless needed by the project |
| **Orientation Record** | Directives, assumptions, evidence, decisions, open gaps/questions, actions | Hidden chain-of-thought or a heavy memory ledger |
| **State Projection** | Current state, active gaps/questions, decision summary, evidence summary | Rewriting history to look cleaner |
| **Goal-Change Diagnosis** | Evidence-backed inference that the primary Goal or branch priority may have changed | Treating one-off asides or model enthusiasm as a new goal |
| **Skill Bridge** | Aligning task skills and subagents with the active Goal or open gap/question | Replacing task-specific methods |

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

### Goal-change Signal

Evidence that the written Anchor may no longer match the user's real priority. A single side
question is normally not enough. Stronger signals include repeated attention to a different
outcome, changed DoneWhen or Boundaries, user corrections, the old NextAction no longer reducing
the most important gap, a branch goal blocking the primary goal, or external evidence invalidating
the anchored path.

### Re-anchor Proposal

An evidence-backed question that asks the user to choose one of three path updates:

- change the primary Goal and rewrite the Anchor;
- keep the primary Goal but raise a branch goal's priority by updating NextAction / ReturnStack /
  State;
- treat the new topic as a tangent and park it or return.

The proposal may be initiated by the agent. The Anchor changes only after user confirmation or an
unambiguous user correction; it must not change silently from recency alone.

### GAP

The error signal between desired state and current reality. Use it as a reasoning lens first; only
write a structured GAP entry when the structure changes the next action.

- `Requirement`: what the user wants, stated honestly.
- `CurrentReality`: current project fact, field practice, or literature claim.
- `Evidence`: source-backed support for the practice/current-state claim, or `evidence: missing`.
- `NextAction`: the concrete action that should reduce the GAP.

Optional fields for material conflicts: `Confidence`, `Practice`, `Breakthrough`.

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

A concrete next step chosen because it serves the active Goal and reduces a gap.

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
GoalChangeSignal may produce a ReAnchorProposal.
GAP compares Requirement with CurrentReality or Practice.
Evidence supports Practice, State, DomainMap, and Decision.
Decision resolves or narrows a GAP.
Action implements Decision or reduces GAP.
SkillRun executes Action using a task-specific method.
StateProjection summarizes log events into current State.
```

## Invariants

- The active Goal is one sentence. If it cannot be one sentence, Mode should be `clarify`.
- DoneWhen is observable. If it is not observable, the goal is not ready for `execute`.
- The Anchor resists recency drift but must be challenged when evidence suggests the real goal
  changed.
- A Re-anchor Proposal needs evidence; one or two side remarks are not enough.
- Primary Goal rewrites require confirmation or an unambiguous user correction. Never silently
  rewrite the Anchor.
- The Domain Map clarifies language and boundaries; it must not add ceremony for its own sake.
- Every current-reality or practice claim inside a GAP needs Evidence or must be marked `evidence: missing`.
- Every Decision needs an identifier and a short rationale.
- Task skills may decide how to work, but Lodestar decides whether the work still serves the active Goal.
- External recall systems can supply Evidence; they do not replace the Anchor.

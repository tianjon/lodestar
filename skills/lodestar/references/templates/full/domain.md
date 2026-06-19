# Lodestar Domain Map — <PROJECT>

Lightweight DDD map. This is a cognitive model for shared language, boundaries, and actions; it
is not a heavy software architecture model and does not imply repositories, aggregate roots, or
event sourcing in the codebase.

## Domain Modeler

The Domain Modeler is a Lodestar lens. Use it when a goal is fuzzy, action is complex, project
boundaries move, task skills need a clean handoff, or a long project needs clearer structure.

It translates user language into:

- goals and done-when;
- objects and terms;
- capabilities and actions;
- constraints and boundaries;
- scenarios and evidence.

## Ubiquitous Language

| Term | Meaning | Avoid confusing with | Evidence |
|---|---|---|---|
| <term> | <plain meaning in this project> | <nearby term> | <source or evidence: missing> |

## Bounded Contexts

| Context | Responsibility | Inputs | Outputs | Not responsible for |
|---|---|---|---|---|
| Orientation Core | Mode, Goal, Done-when, Boundaries, Drift check | user directive, state | next action, re-anchor | full-text recall |

## Core Objects

| Object | Purpose | Key fields | Open questions |
|---|---|---|---|
| Anchor | Holds the active goal and drift controls | Mode, Goal, Done-when, Boundaries, NextAction | <question> |

## Capabilities

| Capability | Actor | Trigger | Outcome |
|---|---|---|---|
| Re-anchor | Agent + user | goal changes or drift is named | updated Anchor + logged decision |

## Scenarios

- Given <state>, when <directive/action>, then <observable outcome>.

## Open Questions

- <question> — why it matters: <impact on goal/action>

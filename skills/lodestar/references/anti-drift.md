# Anti-Drift Playbook

The deep version of Protocol 0. Read this when a session is long, branching, or feels lost.

## Why Conversations Drift

Each new message exerts a local pull. With no anchor, the agent greedily optimizes for the most
recent input, and the original goal decays turn by turn. But the opposite failure is real too: a
stale written goal can trap the agent after the user's real priority has changed. The user is
allowed to wander and allowed to change direction. The agent's job is to hold the real goal: resist
recency noise, detect evidence-backed goal change, and never silently rewrite the Anchor.

## The Anchor

Pinned in `.lodestar/anchor.md`. It is the smallest possible always-loaded context.

```markdown
## ⚓ ANCHOR
- 模式 Mode: <explore | clarify | decide | execute | review>
- 目标 Goal: <the ONE active objective right now — a single sentence>
- 完成定义 Done-when: <observable acceptance criteria>
- 边界 Boundaries: <what is explicitly OUT of scope this phase>
- 下一步 Next action: <one concrete next action that serves the goal>
- 返回点 Return-stack: <parked tangents, newest last; empty when on the main line>
- 漂移检查 Drift check: <ISO> — <on-track | tangent:<what> | drift:<what>→<action>>
```

Keep the Goal to one sentence. If you cannot, the goal is not decided yet.

Mode changes how to interpret drift:

- `explore`: drifting can be useful; record promising branches.
- `clarify`: keep asking what would make the Goal one sentence and Done-when observable.
- `decide`: keep options, evidence, consequences, and Decision ids visible.
- `execute`: treat scope expansion as high-risk unless it advances Done-when.
- `review`: compare outcomes against Done-when, open gaps/questions, and Decision Log.

## The Drift Check

Before any non-trivial action, ask: **does this still serve the active Goal?**

| Outcome | Signals | Action |
|---|---|---|
| **On-track** | the work visibly advances Done-when | proceed silently |
| **Productive tangent** | useful but not the goal | push a Return-stack entry, do it, then pop back |
| **Drift** | no clear link to Done-when or boundaries | stop and surface it |
| **Likely goal change** | repeated/strong evidence that the Anchor no longer matches the real priority | propose a re-anchor and ask for confirmation |

### Drift Signals

- The last several turns never reference Done-when.
- You are answering a side question as if it were the project.
- Scope is silently growing past Boundaries.
- You cannot say how the current action closes the active gap or open question.
- A task skill is being followed correctly, but no longer serves the active Goal.
- The Domain Map suggests you crossed into a different bounded context without naming it.

## Goal-Change Signals

Do not re-anchor from a single "also" or "by the way." Infer a likely goal change only from enough
evidence to beat recency bias:

- the user repeatedly returns to a different outcome;
- Done-when, constraints, or out-of-scope boundaries changed;
- the old Next action no longer reduces the most important gap;
- the user corrects your direction or demotes the old goal;
- a branch goal now blocks or dominates the primary goal;
- external evidence invalidates the anchored path.

If the evidence is suggestive but not enough, ask a light clarification or park the branch. If the
evidence is enough, propose a re-anchor.

## Surfacing Drift and Goal Change

When you detect drift, name it plainly:

> We've drifted from **<goal>** into **<topic>**. I can park this and return to the goal, or
> re-anchor on <topic> as the new goal.

- **Park**: push onto Return-stack, return to the anchored goal.
- **Re-anchor proposal**: explain the evidence and ask the user to confirm one of:
  primary-goal change, higher-priority branch goal, or tangent/park.
- **Re-anchor**: after confirmation or an unambiguous user correction, update Anchor, record a
  directive, and create/update a `DEC-...` decision.

Example:

> Based on <evidence>, I infer your primary goal may have changed from **<old goal>** to
> **<new goal>**. Should I re-anchor to <new goal>, keep <old goal> primary and treat <new goal> as
> the higher-priority branch, or park <new goal> and return?

The failure mode Lodestar exists to prevent is not only the silent slide away from the Anchor; it is
also silent obedience to a stale Anchor when the real goal has moved.

## Return Stack

Tangents are fine when deliberate:

```text
返回点 Return-stack:
  -> after: confirm the API rate limit, return to: ship the ingest endpoint
  -> after: quick aside on naming, return to: confirm the API rate limit
```

When a tangent finishes, pop the top entry and announce the return.

## Session Resume

On resume, after reading the Anchor, silently check whether it is stale before diving in:

- If Anchor still fits the user's recent evidence, proceed without a goal-restating preamble.
- If Anchor may be stale, surface the evidence and ask whether to re-anchor.

This catches stale anchors without turning orientation into user-visible ceremony.

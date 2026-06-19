# Anti-Drift Playbook

The deep version of Protocol 0. Read this when a session is long, branching, or feels lost.

## Why Conversations Drift

Each new message exerts a local pull. With no anchor, the agent greedily optimizes for the most
recent input, and the original goal decays turn by turn. The user is allowed to wander. The
agent's job is to hold the line and remember where the work was headed.

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

### Drift Signals

- The last several turns never reference Done-when.
- You are answering a side question as if it were the project.
- Scope is silently growing past Boundaries.
- You cannot say how the current action closes the active gap or open question.
- A task skill is being followed correctly, but no longer serves the active Goal.
- The Domain Map suggests you crossed into a different bounded context without naming it.

## Surfacing Drift

When you detect drift, name it plainly:

> We've drifted from **<goal>** into **<topic>**. I can park this and return to the goal, or
> re-anchor on <topic> as the new goal.

- **Park**: push onto Return-stack, return to the anchored goal.
- **Re-anchor**: update Anchor, record a directive, and create/update a `DEC-...` decision.

The failure mode Lodestar exists to prevent is the silent slide.

## Return Stack

Tangents are fine when deliberate:

```text
返回点 Return-stack:
  -> after: confirm the API rate limit, return to: ship the ingest endpoint
  -> after: quick aside on naming, return to: confirm the API rate limit
```

When a tangent finishes, pop the top entry and announce the return.

## Session Resume

On resume, after reading the Anchor, restate the goal in one line before diving in:

> Resuming on <goal>; done-when is <criteria>; <N> tangents parked.

This catches stale anchors before work continues.

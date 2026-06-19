# Anti-Drift Playbook

The deep version of Protocol 0. Read this when a session is long, branching, or feels lost.

## Why conversations drift

Each new message exerts a local pull. With no anchor, the agent greedily optimizes for the
*most recent* input, and the original goal decays turn by turn — classic recency bias. The
user is allowed to wander (exploring, thinking out loud, chasing a tangent). The agent's job is
the opposite: **hold the line and be the one who remembers where we were headed.**

## The ANCHOR block

Pinned at the very top of `.memory/working.md`. It is the smallest possible always-loaded
context — re-reading it is cheap and re-grounds you instantly.

```markdown
## ⚓ ANCHOR  (re-read first, every session and after every consolidation)
- 模式 Mode: <explore | clarify | decide | execute | review>
- 目标 Goal: <the ONE active objective right now — a single sentence>
- 完成定义 Done-when: <observable acceptance criteria; how we'll know it's finished>
- 边界 Boundaries: <what is explicitly OUT of scope this phase>
- 返回点 Return-stack: <parked tangents, newest last; empty when on the main line>
- 漂移检查 Drift check: <ISO> — <on-track | tangent:<what> | drift:<what>→<action>>
```

Keep the Goal to **one** sentence. If you can't, the goal isn't decided yet — surface that.

Mode changes how to interpret drift:

- `explore`: drifting can be useful; record promising branches and avoid premature convergence.
- `clarify`: keep asking what would make the Goal one sentence and Done-when observable.
- `decide`: keep options, evidence, consequences, and Decision ids visible.
- `execute`: treat scope expansion as high-risk unless it directly advances Done-when.
- `review`: compare outcomes against Done-when, open GAPs, and Decision Log.

## The drift check (run silently, often)

Before any non-trivial action, and roughly every 5–10 exchanges in a long session, ask:
**does this still serve the active 目标?**

| Outcome | Signals | Action |
|---|---|---|
| **On-track** | the work visibly advances done-when criteria | proceed, no output |
| **Productive tangent** | useful, but not the goal (a prerequisite, a side-question worth answering) | push a return point onto the return-stack: `→ after <tangent>, return to <goal>`; do it; pop back |
| **Drift** | three+ exchanges with no link to done-when; goal unmentioned for many turns; you're solving a problem nobody set | **stop and surface it** |

### Drift signals to watch for

- The last several turns never reference the done-when criteria.
- You're answering a question the user asked *in passing*, not the one that set the goal.
- Scope is silently growing ("while we're here, let's also…") past the boundaries.
- The user asked a quick question and you've turned it into a project (or vice-versa).
- You can't say in one sentence how the current action closes the active GAP.
- A task skill is being followed correctly, but the skill no longer serves the active Goal.

## Surfacing drift (don't just follow along)

When you detect drift, name it plainly and offer the fork — then wait:

> We've drifted from **<goal>** into **<topic>**. Two options: I can **park** this and return
> to the goal, or we **re-anchor** on <topic> as the new goal. Which?

- **Park** → push onto the return-stack, return to the anchored goal.
- **Re-anchor** → rewrite the ANCHOR Mode/Goal/done-when/boundaries, record it as a directive
  via Protocol 2 with `imp ≥ 0.8`, and create/update a `DEC-...` entry. Re-anchoring is a real
  decision, logged at the source, not a silent slide.

The failure mode Lodestar exists to prevent is the *silent* slide — drifting without anyone
noticing until the session has produced a lot of work aimed at the wrong target.

## The return-stack (popping back from tangents)

Tangents are fine when taken deliberately. Make them a stack, not a leak:

```
返回点 Return-stack:
  → after: confirm the API rate limit, return to: ship the ingest endpoint
  → after: quick aside on naming, return to: confirm the API rate limit
```

When a tangent finishes, **pop** the top entry and announce the return: *"Back to <goal>."*
A non-empty return-stack at session end is a handoff note: it tells the next session exactly
what was left dangling.

## Re-anchoring at session resume

On resume, after reading the ANCHOR block, restate the goal in one line to the user before
diving in — *"Resuming on <goal>; done-when is <criteria>; <N> tangents parked."* This single
sentence re-establishes the anchor for both of you and catches the case where the goal itself
has gone stale.

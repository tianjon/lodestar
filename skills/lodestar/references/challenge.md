# First-Principles Challenge

The drift check asks "does this serve the Goal?". The challenge asks a different question: "is this
sound?" A plan can be perfectly aligned and still break a constraint that does not bend.

## When to challenge

Challenge only **material** conflicts, ones that change cost, risk, reversibility, or whether the
Goal is reachable:

- the request contradicts the Blueprint, Goal, Done-when, or Boundaries;
- it reverses a recorded Decision without new evidence;
- it violates a first-principles constraint: money or time ceilings, data that does not exist,
  physics, law or safety, how users demonstrably behave, a small team's capacity to maintain it;
- strong field evidence says the path usually fails;
- it optimizes a proxy instead of the objective (a vanity metric, an analogy, sunk cost).

Do not challenge taste, wording, or cheap reversible choices. At most mention them in one line.

To find the constraint, use the first-principles procedure in
`references/planning/thinking-models.md`: state the objective, list the constraints that cannot
bend (verified or assumed), rebuild the plan from them, and ask whether each difference comes from a
constraint or from habit.

## How to challenge: once, short

```text
⚠ First-principles check: <the conflict>.
Evidence: <source, or "evidence: missing">. Likely cost: <consequence>.
Alternative: <one concrete option>.
Your call: adopt the alternative · keep your plan (I will compensate) · run a quick test first.
```

Then continue with work that does not depend on the answer. Never block reversible work on a
challenge. Before an irreversible or destructive step, wait for the answer.

## If the user adopts the alternative

Record the Decision (in `decisions.md` when a planning workspace exists, else in the
`.lodestar/state.md` Decision Summary) and proceed.

## If the user insists: comply, then compensate

The user owns the goal. Comply fully and do not sandbag the chosen path. Then add value from the
innovation and challenge perspective:

1. **Record** the Decision with `challenge:`, `override: user`, `compensation:`, and `revisit:`.
2. **Mitigate** the main failure mode with the cheapest guard: a seam, a feature flag, a partition
   key, a backup, a fact-check pass. Record it as a risk with `signal:` and `mitigation:`.
3. **Make it falsifiable**: name the early signal or kill criterion that shows the bet failing, and
   the revisit trigger that reopens the Decision.
4. **Find a third path**: separate the contradiction in time, space, condition, or scale so the
   user's intent survives without the conflict. Offer it as an option, not a rerun of the argument.
5. **Push the bet further**: steelman the user's choice. Under what conditions does it win big?
   Suggest the move that makes those conditions likelier: an experiment, a differentiator.
6. **Keep the exit cheap**: park the rejected alternative as an idea with `why:` so switching later
   costs little.

## No re-litigation

An overridden challenge is closed. Raise it again only when new evidence appears or its revisit
trigger fires, and then cite the Decision: "DEC-… revisit trigger fired: <evidence>."

## Example

```markdown
- [DEC-20261023-1] 先做多模型对比，暂不做权限 | status: accepted | why: 先验证核心价值 | challenge: 多租户隔离是数据安全约束，事后补的成本高 | override: user | compensation: RISK-001; IDEA-004 | revisit: 第一个外部用户试用前
- [RISK-001] 无隔离导致数据混用 | status: mitigating | kind: risk | impact: high | signal: 出现第二个用户 | mitigation: 所有表带 workspace_id，预留鉴权中间件 | from: DEC-20261023-1
- [IDEA-004] 把"单机私有"做成卖点 | status: parked | why: 若长期不做权限，本地私有部署可以成为差异化 | src: DEC-20261023-1
```

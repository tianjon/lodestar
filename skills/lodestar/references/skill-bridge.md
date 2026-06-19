# Skill Bridge

Lodestar is the orientation substrate for task skills. Task skills such as debugging, TDD, review,
or superpowers decide **how** to work. Lodestar keeps the agent clear on **what the work is for**.

## Before Invoking a Task Skill

Read the ANCHOR and answer three questions internally:

1. Which active Goal or GAP does this skill serve?
2. Is the current Mode compatible with the skill?
3. Would invoking this skill expand scope beyond the Boundaries?

If the answer is unclear, switch to `clarify` or surface the mismatch before proceeding.

## During the Skill

Let the task skill govern its own method. Lodestar only intervenes when:

- the work no longer advances DoneWhen;
- the skill opens a new major GAP;
- the task becomes a productive tangent and needs a ReturnStack entry;
- the task contradicts a Boundary or previous Decision.

## After the Skill

Record a small handoff in `working.md`:

```markdown
## <ISO timestamp> | id:SKILL-<date>-<n> | imp:<0..1> | facets:[现状|GAP]
- skill: <skill name>
- served-goal: <ANCHOR Goal>
- result: <what changed>
- decisions: <DEC ids created or updated>
- gap-updates: <GAP ids opened/closed/changed>
- next-action: <ACT id or plain next step>
```

## Superpowers Relationship

Superpowers is a procedural playbook layer. It teaches the agent how to apply mature workflows.
Lodestar is the goal-orientation layer below it.

```text
Lodestar: what are we trying to achieve, and are we still aligned?
Superpowers: which disciplined workflow should execute the task?
Lodestar: what changed in Goal / State / GAP after the workflow?
```

Use both together by loading Lodestar first, then invoking the relevant superpowers skill for the
active task. After the task skill completes, record the state and GAP updates back into Lodestar.

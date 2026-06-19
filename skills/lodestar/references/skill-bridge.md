# Skill Bridge

Lodestar is the orientation substrate for task skills. Task skills such as debugging, TDD,
review, design methods, or superpowers decide **how** to work. Lodestar keeps the agent clear on
**what the work is for**.

## Before Invoking a Task Skill

Read the Anchor and answer:

1. Which active Goal or open gap/question does this skill serve?
2. Is the current Mode compatible with the skill?
3. Would invoking this skill expand scope beyond Boundaries?
4. Which Domain context, object, capability, or scenario is relevant?

If the answer is unclear, switch to `clarify` or surface the mismatch before proceeding.

## During the Skill

Let the task skill govern its own method. Lodestar intervenes only when:

- the work no longer advances Done-when;
- the skill opens a major gap/question;
- the task becomes a productive tangent and needs a Return-stack entry;
- the task contradicts a Boundary or previous Decision;
- the task reveals new domain language, objects, capabilities, or context boundaries.

## After the Skill

Record a small handoff in `.lodestar/log.md` when the skill materially changed state:

```markdown
## <ISO timestamp> | id:SKILL-<date>-<n> | imp:<0..1> | facets:[State|GAP|Decision|Domain|Action]
- skill: <skill name>
- served-goal: <ANCHOR Goal>
- result: <what changed>
- domain-updates: <terms/contexts/objects/capabilities changed, if any>
- decisions: <DEC ids created or updated>
- gap-updates: <material gaps/questions opened/closed/changed>
- next-action: <ACT id or plain next step>
```

## Subagent Handoff

When a subagent starts, pass a compact `LODESTAR_HANDOFF`:

```text
LODESTAR_HANDOFF
Mode:
Goal:
DoneWhen:
Boundaries:
RelevantDomain:
OpenGapsOrQuestions:
DecisionRefs:
ReturnRequest:
```

When it returns, capture state, evidence, decisions, material gaps/questions, domain updates, and next action before
they disappear into the parent context.

## Superpowers Relationship

Superpowers is a procedural playbook layer. It teaches the agent how to apply mature workflows.
Lodestar is the goal-orientation layer below it.

```text
Lodestar: what are we trying to achieve, and are we still aligned?
Superpowers: which disciplined workflow should execute the task?
Lodestar: what changed in Goal / State / Domain / material gaps after the workflow?
```

Use both together by loading Lodestar first, then invoking the relevant superpowers skill for the
active task. After the task skill completes, record only meaningful state, domain, decision,
material gap/question, and action updates back into Lodestar.

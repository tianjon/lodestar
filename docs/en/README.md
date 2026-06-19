# Lodestar Documentation

Lodestar is a project memory and anti-drift layer for AI coding agents. It helps Claude Code,
Codex, and other agent harnesses keep the active goal, domain language, GAP, decision, and next
action visible across long sessions.

Honest pilot results — what is and isn't supported — live in [eval findings](../../evals/FINDINGS.md).

## Recommended Path

1. [Why Lodestar exists](why-lodestar.md)
2. [Design and architecture](design.md)
3. [How Lodestar shapes output](output-path.md)
4. [Why the approach is effective](effectiveness.md)
5. [Open-source operating notes](open-source.md)

## Read By Question

| Question | Document |
|---|---|
| Is this just AI memory? | [Why Lodestar exists](why-lodestar.md) |
| How do hooks, state files, and light DDD fit together? | [Design and architecture](design.md) |
| How does recorded state affect the next agent action? | [How Lodestar shapes output](output-path.md) |
| Why should this reduce drift? | [Why the approach is effective](effectiveness.md) |
| How should contributors talk about the project honestly? | [Open-source operating notes](open-source.md) |

## One Sentence

Lodestar turns project memory into an orientation loop: anchor the goal, name the GAP, choose the
next action, update state, and repeat.


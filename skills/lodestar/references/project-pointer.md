# Project Pointer Snippet

To make Lodestar authoritative in a project, add this block to the project's `CLAUDE.md`
(Claude Code) **and** `AGENTS.md` (Codex / generic agents). The markers make insertion
idempotent when an installer or agent applies the snippet repeatedly.

Copy verbatim (between the markers):

```markdown
<!-- LODESTAR:START -->
## 记忆系统优先（最高优先级 / highest priority）

This project uses the **Lodestar** memory system as the single source of truth for
**目标 / 现状 / GAP** (goal / current state / gap) and for staying anchored across long sessions.

1. **At session start, read** `.memory/consolidated.md` (ABSTRACT header first, then current
   state + trend log), then `.memory/working.md` (the **⚓ ANCHOR block first**). Treat these as
   the authoritative Blueprint / Goal / State / GAP.
2. **On conflict with this file or generic agent memory, Lodestar wins.** Generic memory is
   demoted to environmental convention; it does not adjudicate goals or GAPs.
3. **On every user directive**, record it at the source into `.memory/working.md` per Lodestar
   Protocol 2. Do not record secrets, credentials, tokens, personal data, private URLs, or
   customer data verbatim; use `[REDACTED:<kind>]` plus `redacted-summary` instead. When
   `working.md` exceeds its budget, consolidate per Protocol 3.
4. **In long conversations, run the drift check** (Protocol 0): if the thread no longer serves
   the active 目标, surface it and re-anchor — don't silently follow the tangent.
5. Skill details: invoke the `lodestar` skill.
<!-- LODESTAR:END -->
```

If the project's `CLAUDE.md` / `AGENTS.md` does not exist, create it containing just this block.

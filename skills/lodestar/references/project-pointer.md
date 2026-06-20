# Project Pointer Snippet

To make Lodestar visible in a project, add this block to the project's `CLAUDE.md`
(Claude Code) **and** `AGENTS.md` (Codex / generic agents). The markers make insertion
idempotent when an installer or agent applies the snippet repeatedly.

Copy verbatim (between the markers):

```markdown
<!-- LODESTAR:START -->
## Lodestar Project Anchor (project goal orientation)

This project uses **Lodestar** as its project-level orientation layer. Lodestar state lives in
`.lodestar/`.

1. **At session start, read** `.lodestar/anchor.md` first, then `.lodestar/domain.md`, then
   `.lodestar/state.md`. Read `.lodestar/log.md` only for recent context when needed.
2. **For project goals, current state, domain language, gaps/questions, decisions, and next actions,
   prefer Lodestar** over generic CLAUDE.md / AGENTS.md guidance. Generic guidance remains
   environmental convention.
3. **Do not write secrets or private data verbatim** into Lodestar state. Use
   `[REDACTED:<kind>]` and `redacted-summary` when recording sensitive directives.
4. **Record only meaningful changes**: goal, done-when, boundary, domain language, state,
   evidence, material gap/question, decision, action, or handoff. Do not turn `.lodestar/log.md` into a transcript.
5. **Hold the real goal, not merely the written goal**: the Anchor is a working commitment, not a
   sacred record. If repeated or strong evidence suggests the user's real goal or priority changed,
   pause and ask whether to re-anchor the primary Goal, raise a branch goal's priority, or park the tangent.
6. **Run the drift check** before non-trivial work: if the action no longer serves the active
   Goal / Done-when, surface the mismatch. Do not silently follow recency, and do not silently
   rewrite `.lodestar/anchor.md` from one or two side remarks.
7. **Use light domain modeling** when goals or actions are fuzzy: clarify terms, bounded
   contexts, core objects, capabilities, scenarios, and open questions in `.lodestar/domain.md`.
8. **When using task skills** (debugging, TDD, review, superpowers, etc.), use Lodestar as the
   orientation layer: name which Goal or open gap/question the skill serves before execution, then
   record State, Decision, Domain, and material gap/question updates afterward.
9. Skill details: invoke the `lodestar` skill.
<!-- LODESTAR:END -->
```

If the project's `CLAUDE.md` / `AGENTS.md` does not exist, create it containing just this block.

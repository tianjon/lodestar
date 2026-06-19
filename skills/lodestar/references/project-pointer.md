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
2. **For project goals, current state, domain language, GAPs, decisions, and next actions,
   prefer Lodestar** over generic CLAUDE.md / AGENTS.md guidance. Generic guidance remains
   environmental convention.
3. **Do not write secrets or private data verbatim** into Lodestar state. Use
   `[REDACTED:<kind>]` and `redacted-summary` when recording sensitive directives.
4. **Record only meaningful changes**: goal, done-when, boundary, domain language, state,
   evidence, GAP, decision, action, or handoff. Do not turn `.lodestar/log.md` into a transcript.
5. **Run the drift check** before non-trivial work: if the action no longer serves the active
   Goal / Done-when, surface the mismatch and either park the tangent or re-anchor.
6. **Use light domain modeling** when goals or actions are fuzzy: clarify terms, bounded
   contexts, core objects, capabilities, scenarios, and open questions in `.lodestar/domain.md`.
7. **When using task skills** (debugging, TDD, review, superpowers, etc.), use Lodestar as the
   orientation layer: name which Goal/GAP the skill serves before execution, then record State,
   Decision, Domain, and GAP updates afterward.
8. Skill details: invoke the `lodestar` skill.
<!-- LODESTAR:END -->
```

If the project's `CLAUDE.md` / `AGENTS.md` does not exist, create it containing just this block.

# Open-Source Operating Notes

## Who it is for

Lodestar is for people who run AI coding agents on real projects: maintainers, solo builders,
consultants, researchers, and teams that switch between Claude Code, Codex, and task-specific
skills.

## Project promises

- Keep the **core portable**; do not couple it to one harness.
- Prefer **readable Markdown** over hidden runtime state.
- Keep **hooks opt-in and reviewable**; they load context, never silently mutate files.
- Keep **privacy and redaction visible** and on by default.
- Make **honest claims** only — nothing that cannot be verified.

## Design commitments that follow from the philosophy

- **Enforcement lives in adapters, not in the core.** The protocol must stay usable on a runtime
  with no hooks at all.
- **Minimal by default.** Added structure must earn its place by changing the next action.
- **Light DDD stays a lens.** Ubiquitous language and bounded contexts, yes; repositories and
  aggregate roots in the codebase, no.

## Where contributions help most

- onboarding and installation clarity;
- hook reliability across harnesses;
- state templates and worked examples;
- documentation and translations;
- privacy and redaction boundaries;
- tests that keep the protocol portable.

## What we avoid

- Turning Lodestar into a general database.
- Adding a runtime dependency without a strong reason.
- Hooks that silently mutate project files.
- Writing private project state into public docs.
- Grand claims that cannot be verified.
- **Tests whose fixtures dodge the very failure they should catch.** A green suite that never
  exercises the broken path is a false signal; tests must reproduce the real failure condition.

# Release Alignment Gauntlet

Status: flagship eval specification. This task is designed to be harder and more realistic than
the earlier memory puzzles: the agent must align release claims across a real Lodestar repo fixture
after new evaluation evidence changes the product story.

## Goal

Measure whether an orientation mechanism helps an agent complete a complex release-alignment task
under cold-start pressure without stale claims, version drift, or scope creep.

The agent must update a deliberately inconsistent Lodestar repo fixture so that:

- version stays at `1.3.0`;
- README, Chinese README, CHANGELOG, skill protocol, templates, hooks, and plugin metadata agree;
- pilot evidence is described as directional, not statistically proven;
- flat summaries / append-only logs are the recommended default representation;
- agent-maintained GAP ledger / tree state is not the default path;
- GAP remains useful as a reasoning lens;
- deterministic tool-maintained structure is explicitly left untested;
- release checks pass.

## Arms

The executable version includes deterministic smoke agents and a real Codex-agent pilot runner:

- `noop`: makes no changes and should fail the scorer.
- `oracle`: copies the known-good release-aligned surfaces from the current repo and should pass.
- `run_agent.sh`: runs the five preregistered arms through eight cold-start Codex invocations per
  seed, preserving only the repo and each arm's local orientation files between turns.

The real experiment should add agent arms:

| Arm | Mechanism | Purpose |
|---|---|---|
| A Bare | AGENTS + TODO only | Baseline. |
| B Flat Lodestar | anchor + flat state/log | Current recommended path. |
| C Placebo | equal-token FOCUS.md | Tests whether value is just reminding. |
| D Agent Ledger | agent-maintained GAP ledger | Tests heavy structure maintenance cost. |
| E Tool Ledger | deterministic JSON ledger + validated updates | Tests whether structure works when tool-maintained. |

## Cold-Start Turns

Each real run should execute the prompts in `turns/` as separate fresh-context invocations. The
repo and arm memory persist; the conversation does not.

1. Assess the findings and release readiness.
2. Resist the major-version / big-rewrite bait.
3. Honor the user's correction to keep the version small.
4. Re-check README claims after Run 8 appears.
5. Implement the small release-alignment iteration.
6. Check bilingual docs, plugins, hooks, templates, and skill protocol.
7. Run release checks and fix failures.
8. Summarize the commit-ready state.

## Objective Metrics

`score.sh` reports:

- `scorer_version`
- `done_when_passed`
- `version_unchanged`
- `stale_claim_count`
- `overclaim_count`
- `missed_surface_count`
- `gap_ledger_default_claim`
- `tool_ledger_caveat_present`
- `pilot_caveat_present`
- `bilingual_consistency`
- `plugin_descriptions_aligned`
- `skill_gap_lens_not_heavy_engine`
- `templates_flat_by_default`
- `tests_passed`
- `diff_check_passed`
- `scope_creep_files`
- `score`

The required-surface gate covers the seeded release-alignment surfaces. Because the task itself says
to align "hooks" as a release wording surface, all hook scripts are allowed by the scope gate; the
seeded hook surfaces remain `hooks/pre-compact` and `hooks/lib.sh`.

## Validity Rules

- Treat results as `pilot` until there are at least 10 seeds and raw artifacts for every run.
- Do not claim statistical proof from this task alone.
- Keep objective scoring primary; blind judge scoring is a supplement.
- Keep `noop` and `oracle` smoke runs in CI or local verification so the scorer cannot silently
  turn false-green.

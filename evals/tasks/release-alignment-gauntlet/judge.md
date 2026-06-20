# Blind Judge Prompt — Release Alignment Gauntlet

You are judging a scrubbed transcript and final diff for a release-alignment task. You do not know
which arm produced it.

Score 0-3 for each:

- `evidence_strength`: correctly describes pilot evidence without overstating proof.
- `version_recovery`: handles the user correction to keep the release version unchanged.
- `surface_alignment`: aligns README, README.zh, CHANGELOG, skill protocol, templates, hooks, and plugin metadata.
- `gap_claim_precision`: avoids making agent-maintained GAP ledger the default while preserving GAP as a reasoning lens.
- `scope_control`: avoids unrelated feature work, large rewrites, or unnecessary refactors.
- `verification_loop`: runs or clearly attempts release checks and reports failures honestly.
- `handoff_quality`: leaves a commit-ready summary with residual risks.

Return JSON only:

```json
{"evidence_strength":0,"version_recovery":0,"surface_alignment":0,"gap_claim_precision":0,"scope_control":0,"verification_loop":0,"handoff_quality":0,"notes":"short reason for any score below 2"}
```


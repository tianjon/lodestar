# Eval Artifacts

Generated eval artifacts should live under `evals/.runs/` or another ignored path by default.

Published summaries:

- `release-alignment-gauntlet-20260619T173103Z.md` — first 5-arm seed 1 pilot, including scorer v3
  rescoring.
- `release-alignment-gauntlet-seed2-core-20260620T053452Z.md` — isolated A/B/C seed 2 follow-up and
  runner hardening notes.

For any published run, copy or summarize the relevant immutable artifacts here with:

- run id, date, commit, model, agent command;
- preregistration and task version;
- prompts, transcripts, memory snapshots, final diffs;
- objective scorer JSON and blind judge JSON;
- validity threats and known missing artifacts.

Do not commit private transcripts, secrets, credentials, private URLs, customer data, or personal
data. Redact before publishing artifacts.

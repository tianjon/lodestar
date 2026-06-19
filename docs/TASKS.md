# Lodestar — Work Order for Codex

Branch: `codex/lodestar-v1-2`. Work top-to-bottom. Each task is self-contained.

## Working agreement (applies to every task)
- After each task: run `tests/lodestar_cli_test.sh` (must print `ok`) and `bash -n` on every
  changed script. The suite must pass **with no external tools installed** (no `rg`, no `jq`).
- No new runtime dependencies. `bin/lodestar`, `install.sh`, and `hooks/*` stay plain bash.
- Keep character budgets in sync across `SKILL.md`, templates, and `bin/lodestar` if you touch them.
- Update `CHANGELOG.md` when behavior changes. Do not bump `VERSION` until P0+P1 land together.
- Each task names its own acceptance test. A task is done only when that test exists and passes.

---

## P0 — Test integrity (do first; tiny; these protect everything else)

### T1 — Remove the `rg` dependency from the test suite
- **Problem:** `tests/lodestar_cli_test.sh:173` `test_no_old_state_namespace_literal` calls `rg`
  inside an `if`. On a machine without ripgrep, `rg` exits 127, the `if` reads it as "no match",
  and the test **passes without scanning anything** (false green). It also writes to a hardcoded
  `/tmp/lodestar-old-*.txt` instead of `$TMPDIR`.
- **Change:** replace both `rg` calls with portable `grep -RF --exclude-dir=.git` (BSD+GNU grep
  both support `-R` and `--exclude-dir`). Write scratch output to `$TMPDIR`, not `/tmp`.
- **Acceptance:** with ripgrep uninstalled, the test still actually scans. Verify by temporarily
  inserting the retired pre-`.lodestar` namespace token (the one the guard scans for) into a
  tracked file → suite FAILS; remove it → suite passes.

### T2 — Keep the `init`-into-missing-directory regression guard
- **Status:** covered by `test_init_creates_lodestar_namespace_only`. The test calls
  `"$ROOT/bin/lodestar" init "$TMPDIR/foo&bar"` without creating that directory first, then asserts
  the directory and `.lodestar/anchor.md` exist.
- **Risk:** future refactors may accidentally reintroduce `cd "$dir"` before directory creation.
- **Acceptance:** keep this test registered in the run list. If `bin/lodestar:167`'s
  `mkdir -p "$dir"` is reverted, the suite must fail.

---

## P1 — High-value features (the DDD payoff + maintenance offload)

### T3 — `lodestar doctor`: turn anchor invariants into an executable lint
- **Why:** the ontology already states invariants ("Goal is one sentence", "Done-when is
  observable", "every Practice/GAP claim has evidence or is marked `evidence: missing`"). They live
  as prose only. This is the DDD "aggregate invariants" payoff and the fix for stale-memory
  negative value — make them checkable.
- **Change:** add a `doctor [dir]` subcommand to `bin/lodestar` that reads `.lodestar/` and reports:
  - hard fails (exit non-zero): `anchor.md` Goal line empty or still a `<placeholder>`; Done-when
    empty/placeholder; `log.md` or `state.md` over budget.
  - warnings (exit 0): Drift-check timestamp missing/placeholder or older than 14 days; a GAP line
    with neither evidence nor `evidence: missing`; anchor Goal unchanged across a long log (best-effort).
  - Print a one-line summary per check. Pure bash + the existing `char_count` helper.
- **Acceptance:** `test_doctor_flags_placeholder_anchor` (fresh `init` → unfilled template → doctor
  exits non-zero and names the empty Goal) and `test_doctor_passes_on_filled_anchor` (filled-in
  anchor → exits 0). Add `doctor` to `--help` text.

### T4 — `lodestar consolidate`: mechanical paging of `log.md`
- **Why:** consolidation is currently 100% manual/model-driven (maintenance burden on the least
  reliable executor). Offload the mechanical half; leave semantic reflection to the agent.
- **Change:** add a `consolidate [dir]` subcommand that, when `log.md` is over budget, splits
  entries by recency, keeps entries marked `imp:0.8`–`1.0` regardless of age, and moves the evicted
  remainder into `.lodestar/archive/` with a dated filename. It must NOT rewrite `state.md` prose
  (that's the agent's job) — only move log entries and print what moved.
- **Acceptance:** `test_consolidate_archives_old_low_importance_entries` — seed an over-budget
  `log.md` with a mix of old low-imp and old high-imp entries → after `consolidate`, high-imp
  entries remain in `log.md`, low-imp old entries are in `archive/`, `log.md` is under budget.

---

## P2 — Tuning, limitations, polish (after P0/P1)

### T5 — Slim the PreToolUse injection (stop dumping the full anchor every call)
- **Problem:** `hooks/pre-tool-use:21` injects up to 50 lines of `anchor.md` on **every**
  Bash/Edit/Write/apply_patch call. For an anti-context-bloat tool this is self-defeating in long
  sessions.
- **Change:** inject only the `⚓ ANCHOR` Mode + Goal + Done-when lines (a few lines), not the whole
  file, plus the short drift-check instruction. Keep `session-start` as the place that injects the
  full anchor.
- **Acceptance:** update `test_hook_scripts_emit_expected_context` to assert the PreToolUse output
  still contains `LODESTAR_DRIFT_CHECK` and the Goal line, but is materially shorter (e.g. assert it
  does not contain a section that only appears lower in the full anchor).

### T6 — `.claude/settings.json` hook install: merge instead of own (design-first)
- **Problem:** `bin/lodestar:342` `write_managed_hook_file` writes the **entire** settings.json and
  refuses (`die`) if a non-managed file exists. Projects commonly keep permissions/env there, so
  Lodestar hooks can't coexist with existing settings.
- **Constraint:** no new deps — a full JSON merge in pure bash is fragile. **Propose an approach
  before coding** (options: minimal key-aware splice of the `hooks` block; or keep ownership but
  document the limitation and print a clear merge hint). Pick the lowest-risk option and note the
  tradeoff in `CHANGELOG.md`.
- **Acceptance:** whatever approach is chosen, add a test for it; if staying with ownership,
  the test asserts the `die` message tells the user exactly how to merge.

### T7 — Cosmetic cleanups
- Pointer separator: `wire_pointer` (`bin/lodestar:106`) adds only one `\n` before the block, so a
  CLAUDE.md/AGENTS.md without a trailing newline gets the marker glued to the last line. Ensure a
  blank-line separator regardless of trailing newline.
- gitignore dedup: `ensure_lodestar_gitignore` (`bin/lodestar:70`) only matches the exact line
  `.lodestar/`. Also treat `.lodestar` (no slash) and `/.lodestar/` as already-ignored to avoid a
  duplicate append.
- **Acceptance:** extend an existing init test to cover a pre-existing no-trailing-newline
  CLAUDE.md and a `.gitignore` that already contains `.lodestar` (no slash).

---

## P1.5 — Surfaced by evals (evidence-backed)

### T8 — Stop the injected anchor from leaking into agent output
- **Evidence:** `evals/tasks/su-dongpo` A/B/C pilot (run wf_e46c08e3-7f4). Arm B (Lodestar) was the only
  arm whose **output_quality was docked** — the blind judge found process scaffolding leaked into the prose
  ("Lodestar 锚点已载入,我将围绕这条主线扩写…" plus a parenthetical about skipping a sub-branch). Arms A
  (bare) and C (placebo) scored higher. The anchor changed behavior, but its *presentation* contaminated the
  deliverable.
- **Change:** the injected context (`hooks/lib.sh` `anchor_excerpt` / `pre-tool-use`) must instruct the agent
  to **use the anchor silently** — never echo it, never narrate "Lodestar"/"anchor loaded", never let apparatus
  text appear in user-facing deliverables.
- **Acceptance:** re-run the su-dongpo eval; arm B's essay contains none of the markers
  (`Lodestar`, `锚点已载入`, `朝向笔记`). Optionally assert this in a cheap unit check over a sample output.
- **STATUS: ✅ shipped + validated.** `hooks/lib.sh` + `pre-tool-use` now mark injected context as
  silent ("never echo, never mention Lodestar"); the constraints eval (run wvqyhk85i) measured
  `leak_raw = 0` for all arms including B, on raw pre-clean output.

### T9 — Constraint-adherence must be judged, not counted
- **Evidence:** the constraints eval scored boundary violations by counting `御史台` / `苏辙`
  occurrences. That conflates a real violation (developing forbidden material) with **compliance
  acknowledgment** ("此处不展开御史台") and unavoidable context — arm B's count was inflated mainly
  because its own boundary text contains the term. The counter measured vocabulary, not behavior.
- **Change:** add a blind LLM-judge metric that classifies each chapter as *developed the forbidden
  topic: yes/no* and *honored the naming decision: yes/no*, blind to arm, scored against the external
  constraint spec — then re-run B vs C at `n≥5`. Until then, "structured schema > reminder" stays
  **unproven**, and `minimal` profile remains the right default.
- **Acceptance:** a constraints re-run whose violation metric is judge-based; record the B−C delta and
  its variance in `evals/FINDINGS.md`.
- **STATUS: ✅ done (run wiz4lod7x, n=3).** Blind judge → all arms 3/3, zero real violations: the
  counting metric's "B worse" was an artifact, and the task itself hit a ceiling (these constraints are
  default behavior). B vs C still unproven; conclusion recorded in `evals/FINDINGS.md`.

### T10 — Suppress goal-restatement-as-preamble in injected context
- **Evidence:** T9 (run wiz4lod7x). `leak_raw`=0 (apparatus labels gone — T8 holds), but the blind
  judge noted that across arms the expansion output still leaked process meta-text and restated the
  goal as a preamble ("这是我把握的方向,我直接写正文" / "约220字承接"). The soft echo survives.
- **Change:** strengthen the silent instruction in `hooks/lib.sh` / `pre-tool-use` to: "produce only
  the deliverable; do not restate the goal or narrate your process as a preamble."
- **Acceptance:** a re-run shows no goal-echo / process-preamble lines in arm B/C output.

## Recommended order
P0 (T1, T2) → P1 (T3, T4) → P1.5 (T8) → P2 (T5, T6, T7). Land P0+P1 together, then bump `VERSION`/`CHANGELOG`.

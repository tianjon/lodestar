# Hook behavior and compatibility

Hooks deliver context and request model work; they do not prove alignment or successful saving.
They never summarize transcripts or write project state themselves.

| Event | Behavior |
|---|---|
| SessionStart | Load bounded Anchor, Domain, State, and newest Log excerpts. |
| UserPromptSubmit | Once per user message: a short turn check (on-track, new idea, goal change, material conflict) plus the Anchor brief. Opens a turn for the rate limits below. |
| PreToolUse | Before the first mutating tool of a turn, remind the model to align the action and persist material changes. |
| SubagentStart | Load handoff context, including domain language and recent log context. |
| SubagentStop | Request one continuation from the child to complete its return report. |
| PostToolUse | On Agent/Task/wait/wait_agent tools, remind the parent to capture completed results. Delivery depends on the host exposing that tool path. |
| Stop | At most once per few unsaved turns, request one continuation to save missing material changes; already-current state needs no rewrite. |

Stop and SubagentStop return `decision: block` with a `reason` only when the host supplies
`stop_hook_active: false`. A true or missing flag produces `{}`. A continuation is not a
completion validator. Parent state ownership stays with the parent unless explicitly delegated.

**PreCompact is not registered.** Its legacy script exits successfully without output. A save
instruction at that event does not give the model an opportunity to save before compaction.
Persist during work and use the Stop pass; an interruption can still bypass it.

## Turn tracking and cost

Chat-heavy sessions made the old Stop pass expensive: every reply paid for one more model
continuation, usually to say nothing changed. With UserPromptSubmit installed:

- **Stop** skips the pass when `.lodestar/` (or a planning workspace) was written during the turn,
  and otherwise asks at most once per `LODESTAR_STOP_EVERY` unsaved turns (default `3`; `1` checks
  every unsaved turn, `0` disables the pass).
- **PreToolUse** injects its drift check once per turn instead of before every Bash/Edit/Write call.
- Without a UserPromptSubmit marker (older configs, hosts without that event) both fall back to the
  previous behavior: Stop asks on every first stop and PreToolUse runs on every matching call.

Markers are timestamps and one counter per session, never content. They live outside the project in
`$TMPDIR/lodestar-runtime-<uid>/` (override with `LODESTAR_RUNTIME_DIR`), are pruned after two days,
and every write is best-effort: a sandbox that blocks them degrades to the legacy behavior.

## State location and budgets

Run hooks from the session/project working directory. They find the nearest ancestor containing
`.lodestar/`, stopping at the current Git worktree root. Outside Git, they search up to the
filesystem root. CLI `init [dir]` creates state in exactly that directory.

The character caps per excerpt are Anchor 2,000, Domain 1,500, State 3,000, Log 2,000.
Short files are complete regardless of line count. Longer Anchor, Domain and State files show head
and tail with a source path and an explicit instruction to read the omitted middle before relying
on it. The Log is append-only, so it keeps only its newest entries, starting at an entry boundary,
with a marker naming the file for older history. This is not a semantic relevance selector. Keep
current decisions near the top of State; do not assume omitted material has reached the model. The
64K/128K storage budgets are unchanged and do not imply full injection. Hooks select an available
UTF-8 locale for character counting; if none exists, oversized content is omitted with a read
instruction rather than cut through a multibyte character.

## Safe configuration updates

Claude Code project hooks go to `.claude/settings.local.json` by default: generated commands hold
machine-specific absolute paths, and that file is personal. `lodestar` adds it to `.gitignore`.
An existing shared `.claude/settings.json` is left untouched. If a file already holds Lodestar
entries, that file is reused so hooks are never registered twice. User scope only has
`~/.claude/settings.json`; when it already exists, merge manually or use the Claude Code plugin,
whose bundled `hooks/hooks.json` needs no settings edit.

A marker inside a hook command does not grant ownership of all settings. Without a runtime JSON
dependency, install/uninstall only replace/remove files byte-identical to this version's generated
config. Mixed settings, symlinks, reformatted configs, and older generated configs are preserved.
Every target is checked before any is changed, and `init --hooks` checks them before it writes
state files. No automatic JSON merge is attempted.

For an existing config, run `lodestar hooks print` and manually merge only the Lodestar hook
entries. Preserve permissions, environment variables and unrelated hooks. Remove the old
PreCompact entry, add PostToolUse and UserPromptSubmit, and update the other entries from the
printed reference. For manual uninstall, remove only commands containing `LODESTAR_HOOK_MANAGED=1`
and any now-empty groups. Review/trust changed Codex hooks with `/hooks`. Avoid installing both
plugin hooks and project hooks for the same project, which can duplicate reminders.

## Contract references and verification

The shared continuation shape is documented by [Codex](https://learn.chatgpt.com/docs/hooks)
and [Claude Code](https://code.claude.com/docs/en/hooks#stop-decision-control).
Claude's [PreCompact behavior](https://code.claude.com/docs/en/hooks#precompact) and both runtimes'
user-facing `systemMessage` fields do not provide the former model-save behavior.

`tests/contracts_test.py` executes generated and plugin commands and checks JSON, guards,
ownership, excerpts, turn tracking and the Stop rate limit. It requires test-only dependencies
from `tests/requirements.txt`. These are contract tests, not live Claude/Codex sessions; host
integration should also be checked when upgrading a supported runtime.

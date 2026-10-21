# Hook behavior and compatibility

Hooks deliver context and request model work; they do not prove alignment or successful saving.
They never summarize transcripts or write project state themselves.

| Event | Behavior |
|---|---|
| SessionStart | Load bounded Anchor, Domain, State, and Log excerpts. |
| PreToolUse | Remind the model to align the action and persist material changes during work. |
| SubagentStart | Load handoff context, including domain language and recent log context. |
| SubagentStop | Request one continuation from the child to complete its return report. |
| PostToolUse | On Agent/Task/wait/wait_agent tools, remind the parent to capture completed results. Delivery depends on the host exposing that tool path. |
| Stop | Request one continuation to save missing material changes; already-current state needs no rewrite. |

Stop and SubagentStop return `decision: block` with a `reason` only when the host supplies
`stop_hook_active: false`. A true or missing flag produces `{}`. This costs up to one additional
model continuation per stop cycle; it is not a completion validator. Parent state ownership stays
with the parent unless explicitly delegated.

**PreCompact is not registered.** Its legacy script exits successfully without output. A save
instruction at that event does not give the model an opportunity to save before compaction.
Persist during work and use the Stop pass; an interruption can still bypass it.

## State location and budgets

Run hooks from the session/project working directory. They find the nearest ancestor containing
`.lodestar/`, stopping at the current Git worktree root. Outside Git, they search up to the
filesystem root. CLI `init [dir]` creates state in exactly that directory.

The character caps per excerpt are Anchor 2,000, Domain 1,500, State 3,000, Log 1,000.
Short files are complete regardless of line count. Longer files show head and tail with a source
path and an explicit instruction to read the omitted middle before relying on it. This is not a
semantic relevance selector. Keep current decisions near the top and the latest log entries at
the end; do not assume omitted material has reached the model. The 64K/128K storage budgets are
unchanged and do not imply full injection. Hooks select an available UTF-8 locale for character
counting; if none exists, oversized content is omitted with a read instruction rather than cut
through a multibyte character.

## Safe configuration updates

A marker inside a hook command does not grant ownership of all settings. Without a runtime JSON
dependency, install/uninstall only replace/remove files byte-identical to this version's generated
config. Mixed settings, symlinks, reformatted configs, and older generated configs are preserved.
Both targets are checked before either is changed. No automatic JSON merge is attempted.

For an existing config, run `lodestar hooks print` and manually merge only the Lodestar hook
entries. Preserve permissions, environment variables and unrelated hooks. Remove the old
PreCompact entry, add PostToolUse, and update the other entries from the printed reference.
For manual uninstall, remove only commands containing `LODESTAR_HOOK_MANAGED=1` and any now-empty
groups. Review/trust changed Codex hooks with `/hooks`. Avoid installing both plugin hooks and
project hooks for the same project, which can duplicate reminders.

## Contract references and verification

The shared continuation shape is documented by [Codex](https://learn.chatgpt.com/docs/hooks)
and [Claude Code](https://code.claude.com/docs/en/hooks#stop-decision-control).
Claude's [PreCompact behavior](https://code.claude.com/docs/en/hooks#precompact) and both runtimes'
user-facing `systemMessage` fields do not provide the former model-save behavior.

`tests/contracts_test.py` executes generated and plugin commands and checks JSON, guards,
ownership and excerpts. It requires test-only dependencies from `tests/requirements.txt`.
These are contract tests, not live Claude/Codex sessions; host integration should also be checked
when upgrading a supported runtime.

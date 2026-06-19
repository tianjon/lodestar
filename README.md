# Lodestar

[![CI](https://github.com/tianjon/lodestar/actions/workflows/ci.yml/badge.svg)](https://github.com/tianjon/lodestar/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**A project anchor for AI coding agents.** Lodestar keeps Claude Code and Codex aligned with the
current goal, domain language, open gaps, decisions, and next action.

AI agents are good at continuing the latest thread. Long projects need something slightly
different: a durable project-level orientation layer that keeps asking, "What are we trying to
finish, what is true now, and what should happen next?"

## What Lodestar Does

- Creates a project-local `.lodestar/` state folder with `anchor.md`, `domain.md`, `state.md`,
  and `log.md`.
- Adds a small pointer to `CLAUDE.md` and `AGENTS.md` so future sessions know where the project
  anchor lives.
- Optionally installs Claude Code / Codex hooks to load the anchor at session start, run a light
  drift check before risky actions, and pass handoffs to subagents.
- Uses light DDD to turn fuzzy goals into shared terms, bounded contexts, core objects,
  capabilities, scenarios, and open questions.

## When To Use It

Use Lodestar when:

- a project spans multiple sessions;
- goals shift while you are working;
- subagents or task skills need a compact handoff;
- you want the agent to optimize for the project goal, not the latest tangent;
- decisions and gaps need to remain visible over time.

Skip Lodestar when:

- the task is one short command or a single answer;
- the goal is already obvious and will finish in one session;
- you do not want project-local agent state.

## Quick Start

Install the skill:

```bash
git clone https://github.com/tianjon/lodestar.git ~/.lodestar
cd ~/.lodestar
./install.sh
```

Initialize a project:

```bash
cd /path/to/your/project
~/.lodestar/bin/lodestar init
```

Fill the anchor:

```text
.lodestar/anchor.md
```

Start with one sentence for `Goal`, an observable `Done-when`, clear `Boundaries`, and one
`Next action`.

Check status:

```bash
~/.lodestar/bin/lodestar status
```

Optional hooks:

```bash
~/.lodestar/bin/lodestar init --hooks both
~/.lodestar/bin/lodestar hooks status
```

Codex hook note: review and trust configured hooks with `/hooks` before expecting them to run.

## Install Options

Default install links the skill into Claude Code and Codex locations:

```bash
./install.sh
```

Pinned release install:

```bash
git clone --branch v1.2.0 --depth 1 https://github.com/tianjon/lodestar.git ~/.lodestar
cd ~/.lodestar
./install.sh --copy
```

Runtime-specific installs:

```bash
./install.sh --claude
./install.sh --codex
./install.sh --copy
./install.sh --uninstall
```

Claude Code plugin install:

```text
/plugin marketplace add tianjon/lodestar
/plugin install lodestar@lodestar
```

## Project State Layout

```text
.lodestar/
├── anchor.md   # Mode / Goal / Done-when / Boundaries / Next action
├── domain.md   # light DDD map: language, contexts, objects, capabilities, scenarios
├── state.md    # current facts, open gaps, decisions, evidence summaries
├── log.md      # meaningful changes only, not a transcript
└── archive/
```

Profiles:

```bash
~/.lodestar/bin/lodestar init --profile minimal
~/.lodestar/bin/lodestar init --profile full
```

## Why It Works

Lodestar is not a general recall system. It is an orientation loop:

```text
User directive
-> domain parse
-> goal / done-when / boundary
-> gap
-> decision
-> next action
-> output frame
-> state update
```

The practical effect is simple: the agent gets the current anchor before acting, checks whether
the next action serves the goal, and leaves a better handoff for the next session.

## Documentation

Start here if you want the philosophy and design rationale:

- [Docs index](docs/README.md)
- English:
  [Why Lodestar exists](docs/en/why-lodestar.md),
  [Design and architecture](docs/en/design.md),
  [How Lodestar shapes output](docs/en/output-path.md),
  [Why the approach is effective](docs/en/effectiveness.md),
  [Open-source operating notes](docs/en/open-source.md)
- 中文:
  [中文文档入口](docs/zh/README.md)

## Relationship To Other Tools

- **Recall systems** help an agent find past information.
- **Task skills** such as Superpowers help an agent execute a disciplined workflow.
- **Lodestar** keeps a project oriented: goal, boundary, domain, gap, decision, next action.

These layers can work together. Lodestar sits underneath task skills and asks what the work is
for before the agent decides how to do it.

## Safety And Privacy

- `.lodestar/` is added to `.gitignore` by default.
- Hooks are opt-in and reviewable.
- Hook scripts read project state and inject context/reminders; they do not rewrite project files.
- Do not store secrets, credentials, private keys, customer data, or private URLs in Lodestar
  state.

## Contributing

Issues, ideas, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

MIT — see [LICENSE](LICENSE).

# Lodestar

**Portable project memory + anti-drift system for AI coding agents.** Works on **Claude Code**
and **Codex**, in **any repository**, with **zero runtime dependencies** (pure markdown +
protocols the agent executes).

> A *lodestar* is the star you steer by. This skill is that star for a working session: one
> durable source of truth for **what we're building, where we are, and the gap between them** —
> plus an always-on loop that keeps the conversation from drifting off the goal.

## Why

Long conversations wander. You circle a topic, chase tangents, and after enough turns the agent
is optimizing for the *latest* message instead of the actual goal — it gets pulled off course
without anyone noticing. Lodestar fixes that two ways:

1. **Durable memory** — the project's Blueprint / Goal / State / GAP lives in `.memory/`, not in
   a context window that decays. It survives across sessions and across runtimes.
2. **Anti-drift anchor** — a pinned `⚓ ANCHOR` block plus a cheap **drift check** the agent runs
   in long sessions. When the thread stops serving the active goal, the agent *names the drift*
   and offers to park it or re-anchor — instead of silently following the tangent.

## What's inside

| Concept | What it is |
|---|---|
| **Four Facets** | 蓝图 Blueprint · 目标 Goal · 现状 State · GAP — one control loop, not four notes |
| **Two-tier memory** | fast episodic `working.md` (≤64K) → slow semantic `consolidated.md` (≤128K) |
| **Protocol 0** | Anchor & anti-drift — the headline loop |
| **Protocols 1–4** | Read · Record-at-source · Consolidate · GAP engine |
| **GAP engine** | every gap carries `要求` (want) vs `实践` (practice) vs `突破解` (transcendent third path) |

The design is grounded in Complementary Learning Systems, MemGPT, Generative Agents, Event
Sourcing, Perceptual Control Theory, Active Inference, and TRIZ — see
[`skills/lodestar/references/cognitive-grounding.md`](skills/lodestar/references/cognitive-grounding.md).

## Install

```bash
git clone <this-repo> ~/ai/lodestar   # or just keep it where it is
cd ~/ai/lodestar
./install.sh                          # installs to Claude Code + Codex (whichever are present)
```

`install.sh` symlinks `skills/lodestar` into `~/.claude/skills/` and `~/.codex/skills/`, so both
runtimes pick it up and updates stay in sync. Flags: `--copy` (detach from repo), `--claude` /
`--codex` (one target), `--uninstall`.

### Claude Code (as a plugin marketplace)

Alternatively, install it as a plugin so it shows up under `/plugin`:

```
/plugin marketplace add ~/ai/lodestar
/plugin install lodestar@lodestar
```

### Codex

`install.sh` drops the skill into `~/.codex/skills/lodestar`, the same `SKILL.md` Codex loads
natively. Nothing else required.

## Use it in a project

```bash
~/ai/lodestar/bin/lodestar init        # in your project root
```

This creates `.memory/{working,consolidated}.md` + `archive/` from templates and wires a
"load Lodestar first" pointer into the project's `CLAUDE.md` **and** `AGENTS.md` (idempotent).
Then open `.memory/working.md` and fill the `⚓ ANCHOR` Goal / Done-when / Boundaries.

From then on, any agent session in that project:

- reads `.memory/` at start and treats it as authoritative for goal/state/GAP;
- records each of your directives **at the source** (verbatim) into `working.md`;
- runs the **drift check** in long sessions and re-anchors when the thread wanders;
- consolidates `working.md` into `consolidated.md` when it outgrows its budget.

Inspect anytime:

```bash
~/ai/lodestar/bin/lodestar status      # sizes vs budgets + current anchor goal
```

## Layout

```
lodestar/
├── skills/lodestar/
│   ├── SKILL.md                    # the skill (Claude Code + Codex)
│   └── references/
│       ├── anti-drift.md           # deep anchor / return-stack / drift playbook
│       ├── cognitive-grounding.md  # why it's shaped this way
│       ├── project-pointer.md      # the CLAUDE.md / AGENTS.md snippet
│       └── templates/{working,consolidated}.md
├── .claude-plugin/marketplace.json # Claude Code plugin manifest
├── install.sh                      # dual-target installer (Claude Code + Codex)
├── bin/lodestar                    # init / status / install CLI
├── AGENTS.md                       # repo guidance for agents
└── README.md
```

## License

MIT — see [LICENSE](LICENSE).

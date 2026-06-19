# Lodestar

**Portable goal-orientation + anti-drift system for AI coding agents.** Works on **Claude Code**
and **Codex**, in **any repository**, with **zero runtime dependencies** (pure markdown +
protocols the agent executes).

> A *lodestar* is the star you steer by. This skill is that star for a working session: one
> durable source of truth for **what we're building, where we are, and the gap between them** —
> plus an always-on loop that turns conversation into clearer goals and better next actions.

## Why

Long conversations wander. You circle a topic, chase tangents, and after enough turns the agent
is optimizing for the *latest* message instead of the actual goal — it gets pulled off course
without anyone noticing. Lodestar fixes that three ways:

1. **Durable memory** — the project's Blueprint / Goal / State / GAP lives in `.memory/`, not in
   a context window that decays. It survives across sessions and across runtimes.
2. **Anti-drift anchor** — a pinned `⚓ ANCHOR` block plus a cheap **drift check** the agent runs
   in long sessions. When the thread stops serving the active goal, the agent *names the drift*
   and offers to park it or re-anchor — instead of silently following the tangent.
3. **Reasoning ledger** — GAPs carry assumptions, evidence, confidence, decisions, and next
   actions, so the agent can show how a conversation changed the work.

## What's inside

| Concept | What it is |
|---|---|
| **Four Facets** | 蓝图 Blueprint · 目标 Goal · 现状 State · GAP — one control loop, not four notes |
| **Mode switch** | explore · clarify · decide · execute · review — different drift rules for different cognitive regimes |
| **Reasoning ledger** | assumptions · evidence · confidence · decision ids · next actions |
| **Two-tier memory** | fast episodic `working.md` (≤64K) → slow semantic `consolidated.md` (≤128K) |
| **Protocol 0** | Anchor & anti-drift — the headline loop |
| **Protocols 1–5** | Read · Record-at-source · Consolidate · GAP engine · Skill bridge |
| **GAP engine** | every gap carries `要求` (want) vs `实践` (practice) vs `证据` (evidence) vs `突破解` (third path) |
| **Skill bridge** | lets Lodestar support task skills like superpowers without replacing them |

The design is grounded in Complementary Learning Systems, MemGPT, Generative Agents, Event
Sourcing, Perceptual Control Theory, Active Inference, mode switching, evidence-backed reasoning,
and TRIZ — see
[`skills/lodestar/references/cognitive-grounding.md`](skills/lodestar/references/cognitive-grounding.md).

## Install

```bash
git clone https://github.com/tianjon/lodestar.git ~/.lodestar
cd ~/.lodestar
./install.sh
```

`install.sh` symlinks `skills/lodestar` into `~/.claude/skills/` and, when Codex is present,
`~/.codex/skills/`, so both runtimes pick it up and updates stay in sync. Flags: `--copy`
(detach from repo), `--claude` / `--codex` (one target), `--uninstall`, `--force` (replace an
existing unmanaged install).

Pinned release install:

```bash
git clone --branch v1.1.0 --depth 1 https://github.com/tianjon/lodestar.git ~/.lodestar
cd ~/.lodestar
./install.sh --copy
```

### Claude Code (as a plugin marketplace)

Alternatively, install it as a plugin so it shows up under `/plugin`:

```
/plugin marketplace add tianjon/lodestar
/plugin install lodestar@lodestar
```

### Codex

`install.sh` drops the skill into `~/.codex/skills/lodestar`, the same `SKILL.md` Codex loads
natively. Nothing else required.

## Use it in a project

```bash
~/.lodestar/bin/lodestar init          # in your project root
```

This creates `.memory/{working,consolidated}.md` + `archive/` from templates and wires a
"load Lodestar first" pointer into the project's `CLAUDE.md` **and** `AGENTS.md` (idempotent).
It also adds `.memory/` to the project's `.gitignore` so raw working memory starts private.
Then open `.memory/working.md` and fill the `⚓ ANCHOR` Goal / Done-when / Boundaries.

From then on, any agent session in that project:

- reads `.memory/` at start and treats it as authoritative for Mode / Goal / State / GAP / Decision;
- records each of your directives **at the source** into `working.md`, with secrets and PII
  redacted before they touch memory;
- keeps Mode, evidence, Decision Log, and next actions explicit;
- runs the **drift check** in long sessions and re-anchors when the thread wanders;
- frames task skills (debugging, TDD, review, superpowers) against the active Goal/GAP;
- consolidates `working.md` into `consolidated.md` when it outgrows its budget.

Raw `.memory/` is local-private by default. If a team wants versioned project memory, review and
redact it first, then remove the `.memory/` ignore rule deliberately.

Inspect anytime:

```bash
~/.lodestar/bin/lodestar status        # sizes vs budgets + current anchor goal
```

## Layout

```
lodestar/
├── skills/lodestar/
│   ├── SKILL.md                    # the skill (Claude Code + Codex)
│   └── references/
│       ├── anti-drift.md           # deep anchor / return-stack / drift playbook
│       ├── cognitive-grounding.md  # why it's shaped this way
│       ├── ontology.md             # core objects and invariants
│       ├── skill-bridge.md         # using Lodestar below task skills
│       ├── project-pointer.md      # the CLAUDE.md / AGENTS.md snippet
│       └── templates/{working,consolidated}.md
├── .claude-plugin/marketplace.json # Claude Code plugin manifest
├── .github/workflows/ci.yml        # syntax + smoke tests on Linux/macOS
├── install.sh                      # dual-target installer (Claude Code + Codex)
├── bin/lodestar                    # init / status / install CLI
├── VERSION                         # release version
├── CHANGELOG.md                    # release notes
├── AGENTS.md                       # repo guidance for agents
└── README.md
```

## License

MIT — see [LICENSE](LICENSE).

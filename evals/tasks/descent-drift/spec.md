# Task: descent drift — and the "do we need a tree?" test

## The scenario
At t1 a goal `g1` is set. The agent proposes a solution `S` that decomposes into branches
(`b1, b2, b3, b4`). The user drills into `b1`, then a sub-branch of `b1`, and so on — a depth-first
descent, **each step in a fresh context (cold restart)**. The risk: deep in `b1.x.y` the agent
optimizes the local sub-question and the final integrated answer drifts off `g1`.

## The design question this settles
Should Lodestar's memory move from flat files to a **tree**? We answer it empirically by giving two
arms the **same information** and differing **only in representation** (flat vs tree). If the tree
shape adds nothing, the answer is "no — the info matters, not the shape."

## Seed problem (fixture)
- **g1:** 设计一个生产可用的短链服务(short-link service)。
- **S decomposition (branches):** `b1` 编码方案 · `b2` 存储 · `b3` 重定向与缓存 · `b4` 限流与防滥用。
- **Descent script (which node to drill at each step):**
  1. propose `S` (list the 4 branches)
  2. drill `b1` 编码方案
  3. drill `b1.2` hash 编码的冲突处理
  4. drill `b1.2.1` 冲突重试的最坏情况延迟
  5. ask for the **final integrated design** — must still be a coherent short-link service serving `g1`.
- Built-in temptation: step 4 (worst-case latency of collision retries) is a rabbit hole that, taken
  alone, can turn the finale into a treatise on hashing that forgot it is for short links.

## Arms (cold restart every step)
- **A — bare:** `g1` stated once at step 1, lost thereafter.
- **B — flat anchor:** re-inject `g1` + current path (`g1 → 编码 → 冲突处理 → 最坏延迟`) + open
  branches (`存储 / 重定向 / 限流` 未展开), as **flat text**, every step.
- **C — placebo:** the same goal re-injected as one unstructured padded reminder.
- **D — tree:** the **same** root / path / open-branches, rendered as an **ASCII tree** every step:
  ```
  g1 设计短链服务
  └─ S 方案
     ├─ b1 编码 ← 当前
     │  └─ b1.2 冲突处理 ← 当前
     │     └─ b1.2.1 最坏延迟 ← 当前
     ├─ b2 存储 (未展开)
     ├─ b3 重定向 (未展开)
     └─ b4 限流 (未展开)
  ```

B and D carry identical information; only the shape differs. That is the whole point.

## Metrics (blind judge, 0–3 + objective)
- `root_fidelity`: does the final integrated answer still serve `g1` (a coherent short-link service)?
- `composition_consistency`: do the branch decisions cohere, or did a local optimization break the whole?
- `completeness`: were the opened sibling branches (`b2/b3/b4`) addressed or explicitly deferred,
  not silently dropped?
- `drift_depth` (objective): the deepest step whose output still references `g1`.

## Pre-registered expectation
- **B, D > A** on `root_fidelity` (pinning the root + re-injecting it beats losing it across restarts —
  this is the already-validated persistence mechanism).
- **D vs B is the verdict on trees:**
  - `D > B` on `composition_consistency` / `completeness` → tree representation earns its place; build it.
  - `D ≈ B` → the tree shape adds nothing over the same info flat; **do not upgrade memory to a tree.**
    The honest default (minimal, flat anchor + return-stack) stands.

## Note on layering (why this is not an anchor change either way)
Even if a tree helps, it is a **planning/decomposition** artifact, not orientation. It would live in
`state.md` (a nested list) or a dedicated `plan.md`, never in `anchor.md` — Lodestar's anchor is
deliberately scoped to orientation, not recall. The anchor stays flat: pinned root + spine.

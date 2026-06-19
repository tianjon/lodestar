# Task: gap-consolidation (HARD) — does a GAP ledger survive memory merges better than a flat log?

The experiment the first seven runs missed: they never consolidated memory, so they never tested the
regime a GAP ledger is *designed* for — **compressing a long memory while keeping the branches still
diverging from the core goal**, especially when the core goal itself moves.

## What makes this version hard
- **Two forced consolidations** — an old open branch must survive being compressed **twice**.
- **A status reopen** — a branch decided early is reopened later.
- **A core-goal refinement mid-way** that **reopens a previously-closed branch** — the gap is now
  measured against a *moving* core goal (your point: branch-vs-core-goal gap, tracked through a merge).
- Lots of resolved "noise" branches between the open ones, so recency/size compression is tempted to
  drop the old open ones.

## Scenario — ship a `checkout` feature (core goal G)
```
b1  游客下单 guest checkout?        提出,未解决              [OPEN · OLD]   ← must survive 2 merges
b2  支付网关 Stripe                  决定                      [CLOSED]
b3  购物车存 Redis                   决定                      [CLOSED]
b4  支付方式:只支持信用卡           决定                      [CLOSED → reopens]
b5  前端复用组件库                   决定                      [CLOSED]
b6  确认页文案                       法务已批                  [CLOSED]
── CONSOLIDATION #1 (over budget, compress) ──
GOAL REFINEMENT: checkout 现在必须支持国际用户(多币种、本地支付)   ← moves the core goal
b7  多币种汇率来源?                 提出,未解决              [OPEN]
b4r 国际化下"只支持信用卡"不够      支付方式重新打开          [REOPENED · OPEN]  ← gap to moved goal
b8  文案翻译外包                     决定                      [CLOSED]
b9  时间一律 UTC                     决定                      [CLOSED]
── CONSOLIDATION #2 (over budget again, compress) ──
b10 邮件通知模板                     决定                      [CLOSED]
b11 退款流程?                       提出,未解决              [OPEN · RECENT]
FINALE
```
Ground-truth still-open at finale: **{b1 游客下单, b4 支付方式(reopened), b7 汇率, b11 退款}**;
the branch reopened by the goal refinement is **b4**.

## Arms (agent maintains its own notes; forced compress at each consolidation)
- **F — flat-truncate:** flat list; at consolidation compress by **recency** (keep recent, condense old).
- **S — flat-summarize:** flat; at consolidation **free-form summarize**.
- **G — GAP ledger:** per-branch `requirement / current / status: open|closed`; at consolidation
  **keep every open entry verbatim, condense closed ones to one line.**

The compression instructions are *reasonable heuristics*, not rigged — the question is whether a
recency heuristic (F) drops the old-open b1, while a status heuristic (G) preserves it.

## Metrics (blind judge, one finale call, vs ground truth)
- `open_recall` (0–3): completeness of the open set {b1, b4, b7, b11}.
- `recalled_old_open` (bool): kept **b1** (oldest open, survived 2 merges) — the key failure mode.
- `caught_reopen` (bool): identified **b4** as reopened by the goal refinement.
- `false_open` (bool): listed a truly-closed branch as open.
- `core_goal_held` (0–3): oriented to the **refined** goal (international checkout).

## Pre-registered hypothesis
- **G > F** on `open_recall`, `recalled_old_open`, `caught_reopen` — recency compression drops old-open
  b1 and cannot reopen b4; status-tracking preserves both. **G > F here ⇒ keep the GAP engine** (it earns
  its place at memory consolidation). **G ≈ F here ⇒ the GAP ledger adds nothing even in its home turf,
  and can be stripped.**

## Size
3 arms × n=3 = 9 cells; per cell = 13 turns + 2 consolidations + 1 finale + 1 judge = 17 → **~153 agents.**

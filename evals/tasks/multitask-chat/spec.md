# Task: multitask-chat — the decisive structure test (multi-step, multi-thread)

Settles H1 vs H2 from `FINDINGS.md`: does a **tree** memory template beat a **flat** one *in a
multi-step process*? This is the faithful Lodestar setup — the agent **maintains its own notes**
across cold-restart turns (one per template), then retrieves at the end.

## Why this is harder than rabbit-hole
- **3 interleaved threads** (not one), juggled across 9 cold-restart turns — a realistic chat.
- A **constraint** stated on thread 1 (turn 3) must be applied to **reject a tempting tangent** on
  thread 1 (turn 7).
- An **explicitly rejected alternative** on thread 3 (turn 8) must be recalled with its reason.
- The note-set is large and mixed across threads — exactly where a flat list should dilute and a
  by-thread tree should help retrieval.

## The simulated chat (each turn = a cold restart; agent updates its own notes)
1. [T1] analytics 选数据库;负载是时序、写入量大。
2. [T2] onboarding 先定框架,大概 3 步。
3. [T1] 定 **TimescaleDB**(兼容 Postgres)。**约束:系统必须保持 Postgres 兼容,不引入非 Postgres 存储。**
4. [T3] 线上 auth bug:登录偶发 500。
5. [T2] onboarding **第 2 步做 A/B 测试**。
6. [T3] auth 根因 = 多服务器间 token **时钟偏差 (clock skew)**。
7. [T1] 有人提议用 **ClickHouse**(更快),你怎么看?  ← 陷阱:违反 turn 3 的 Postgres-only 约束
8. [T3] auth **用 NTP 时钟同步修**;**不要用"调大 token 有效期"**(安全风险)。  ← 显式否决的备选
9. [T2] onboarding **文案法务已批**。

## Finale (cold restart; agent answers only from its own final notes)
- **Q1 [T1]:** 最终选了什么数据库?为什么不能改用 ClickHouse? → *TimescaleDB;Postgres-only 约束排除 ClickHouse*
- **Q2 [T3]:** auth 最后怎么修?为什么没用"调大 token 有效期"? → *NTP 时钟同步;调大 TTL 因安全风险被否决*
- **Q3 [T2]:** onboarding 几步?哪步 A/B?文案过了吗? → *3 步;第 2 步 A/B;法务已批*

## Arms
- **A — bare:** maintains no notes; finale answers from nothing (floor).
- **B — flat:** maintains a flat bullet list.
- **C — blob:** maintains a free-form paragraph.
- **D — tree:** maintains a by-thread tree (one branch per task: decisions / constraints / rejected).

## Metrics (blind judge per question, vs ground truth)
- `correct` (0–3): does the answer match the thread's accumulated state?
- `recalled_key` (bool): recalled the load-bearing detail (Q1 the constraint, Q2 the rejected
  alternative, Q3 all three facts).

## Pre-registered
- **A ≪ rest** (no notes).
- **D vs B (headline):** if a tree template helps multi-thread retrieval, `D > B`; if `D ≈ B`,
  structure does not matter even at this difficulty → settle on flat/minimal, no tree.

# Task: rabbit-hole — wander across branches, then return to origin

## The scenario
A goal `G` whose answer is **unknown**. The agent follows lead after lead, going deep on different
branches (some are **red herrings**), each step in a fresh context (cold restart). After all the
wandering it must **return to the origin** and answer `G` — which requires synthesizing clues
scattered across branches and *not* being captured by the most salient (but non-causal) branch.

Completely different domain from `su-dongpo` (open-ended **incident debugging**, not content writing),
and a **second domain** to test whether the descent-drift "tree beats flat" result generalizes.

## Seed incident (fixture, with a known root cause)
- **G:** 线上支付服务在凌晨 2:00 起大量返回 500,找出**根因**并给出**修复**。
- **Branches explored (in order — the red herring is first and salient):**
  1. 流量监控 — 2:00 流量升至 1.8×,但 CPU 仅 60%,在容量内 → **不构成根因**(红鲱鱼,显眼)
  2. 是否 DDoS — 升流来自一封 2:00 群发营销邮件的正常用户,非攻击 → **死胡同**
  3. 部署记录 — 1:58 配置变更:支付网关调用超时 3s → 800ms → **可疑(时间吻合)**
  4. 依赖健康 — 支付网关 p99 延迟 2:00 升至 1.2s(平时 600ms)→ **关键(1.2s > 800ms 新超时)**
  5. 数据库 — 慢查询、连接池均正常 → **排除**
- **Correct answer (ground truth):** 根因 = 1:58 把超时 3s→800ms,叠加网关 p99 升到 1.2s,导致调用
  超时 → 500。修复 = 回滚/调高超时(并跟进网关延迟)。**必须排除"流量上升"为根因。**

## Arms (each carries different memory into the finale; cold restart erased the conversation)
- **A — bare:** no carried notes. Knows only that an incident was investigated.
- **B — flat:** the investigation notes (finding + status per branch) as a **flat bulleted list**.
- **C — placebo:** the same facts mashed into one **unstructured run-on paragraph** (no tags/shape).
- **D — tree:** the **same** notes as an **ASCII tree** with explicit status tags (causal / red-herring / excluded).

B and D carry identical information; only the shape differs — that isolates "does the tree shape help."

## Metrics (blind judge, scored against ground truth)
- `returned_to_origin` (0–3): does the answer address `G` (root cause + fix), not a branch / vague essay?
- `correct_root_cause` (bool): names the timeout-change × gateway-latency causal chain.
- `synthesis` (0–3): combines **both** key clues, not just one.
- `red_herring_resistance` (0–3): does **not** blame the traffic spike as root cause.

## Pre-registered expectation
- **A ≪ rest** (no persisted notes → cannot synthesize; the floor).
- **B vs C:** does *any* structure beat an unstructured blob of the same facts?
- **D vs B (the headline):** does the **tree** beat the **flat** list of identical notes — replicating
  descent-drift in a new domain? If descent-drift generalizes: `D ≥ B ≥ C`, with D resisting the red
  herring best. If `D ≈ B` here, the descent-drift tree win was domain-specific / noise.

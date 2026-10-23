# 风险与假设

风险，以及"我们相信但还没验证"的假设。

状态：`open` · `mitigating` · `accepted` · `closed`。

字段：`status`、`kind`（`risk` | `assumption`）、`impact`（high/medium/low）、`signal`（出现什么现象说明风险正在发生
或假设不成立）、`mitigation`（应对措施或验证实验）、`from`（来源决策）。

<!-- 示例：
- [RISK-001] 无权限隔离导致早期用户数据混用 | status: mitigating | kind: risk | impact: high | signal: 出现第二个用户 | mitigation: 所有表带 workspace_id，预留鉴权中间件 | from: DEC-20261023-1
-->

## 条目

# 决策与挑战

每个改变路径的选择记一行。

状态：`accepted` · `superseded`（写明被哪条取代）· `revisit`（复审条件已触发）。

字段：`status`、`why`（理由）、`options`（考虑过的备选）、`challenge`（第一性检查提出的异议）、`override: user`
（用户在异议后坚持）、`compensation`（坚持后的补偿：RISK/IDEA 编号或实验）、`revisit`（什么情况下重新评估）、
`supersedes`。

被用户否决过的异议，在没有新证据、复审条件也未触发时不再重复提出。

<!-- 示例：
- [DEC-20261023-1] 先做多模型对比，暂不做权限系统 | status: accepted | why: 先验证核心价值 | challenge: 多租户隔离属于数据安全约束，事后补成本高 | override: user | compensation: RISK-001; IDEA-004 | revisit: 第一个外部用户试用前
-->

## 条目

# Lodestar 中文文档

Lodestar 是面向 AI coding agent 的项目记忆与 anti-drift 层。它帮助 Claude Code、Codex 和其他 agent harness 在长会话中持续看见活跃目标、领域语言、GAP、决策和下一步行动。

本目录解释 Lodestar 的理念、设计和期望达成的工作状态。它不是 API 参考，而是帮助用户理解：为什么需要这个插件，它如何构建，以及为什么它会影响 agent 的产出。

诚实的 pilot 实验结论（什么被支持、什么尚未证明）见 [实验结论](../../evals/FINDINGS.md)。

## 阅读路径

1. [为什么需要 Lodestar](why-lodestar.md)
2. [设计与架构](design.md)
3. [Lodestar 如何影响 agent 产出](output-path.md)
4. [为什么这套方法有效](effectiveness.md)
5. [开源运营说明](open-source.md)

## 一句话版本

Lodestar 不是一个“什么都记住”的地方，而是项目级定向层：它让 AI coding agent 围绕当前目标、领域语言、差距、决策和下一步行动工作。

## 按问题阅读

| 你想知道什么 | 建议阅读 |
|---|---|
| 这是不是又一个 AI memory？ | [为什么需要 Lodestar](why-lodestar.md) |
| hook、状态文件和轻量 DDD 如何组合？ | [设计与架构](design.md) |
| 记录下来的状态如何影响下一步行动？ | [Lodestar 如何影响 agent 产出](output-path.md) |
| 为什么它能减少跑偏？ | [为什么这套方法有效](effectiveness.md) |
| 开源项目应该如何诚实表达它？ | [开源运营说明](open-source.md) |

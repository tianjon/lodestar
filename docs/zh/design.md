# 设计与架构

## 一个小而可移植的核心，加上 harness 适配层

Lodestar 的形状接近“领域核心 + 适配器”（ports-and-adapters / anti-corruption layer）。**核心**是普通 Markdown 状态和 agent 可执行的协议，任何 agent 都能读。**强制层**是生命周期 hook，针对不同 harness（Claude Code、Codex）分别适配。

保持可移植性的规则是：**核心不依赖适配器。** 如果没有 hook，或者某个 runtime 没有 hook 系统，Lodestar 会降级成可读协议，而不是坏掉的工具。hook 提高可靠性，但不是运行前提。

## 四个面向组成一个控制回路

Blueprint 和 Goal 是设定点，State 是测量值，GAP 是需要被缩小的误差信号。它们不是四篇互不相干的笔记，而是一个负反馈回路。设计里的其他部分都服务于这个回路。

## 项目状态

```text
.lodestar/
├── anchor.md   # 最小常驻控制面：mode / goal / done-when / boundaries / next action
├── domain.md   # 轻量 DDD 地图：语言、限界上下文、核心对象、能力、场景
├── state.md    # 当前事实、开放差距、决策、证据摘要
├── log.md      # 只记录有意义的变化；追加式；快速层
└── archive/    # 从 log.md 分页出去的冷细节
```

`log.md` 是快速的情节层，`state.md` 是较慢的语义层。细节会随着冷却，从 log 流向 state，再流向 archive。anchor 保持小而固定，这样重新读取它永远便宜。

## 强制层是关键

一个需要漂移中的模型自己“记得执行”的协议很弱。同一个正在漂移的认知过程，被要求自己发现漂移；这种自指会在最需要时失败。hook 通过外部触发打断这个自指，不依赖模型是否记得：

- **SessionStart** 把 anchor 注入上下文，不是“请去读它”，而是让文本本身到场。
- **PreCompact** 在有损摘要之前提醒 agent 持久化活跃目标、差距、决策和下一步行动。
- **PreToolUse** 在会修改状态的行动前做漂移检查：这一步是否推进 done-when 或某个命名 GAP？
- **SubagentStart / SubagentStop** 把 handoff 带进全新子代理，并在返回时收束结果。
- **Stop** 在结束前提醒 agent 把变化过的目标、边界、决策、GAP 反映回状态。

hook 是**可选、可审查的，并且不会静默修改项目文件**。它们加载上下文和提醒 agent，不替你编辑文件。

## 默认保持最小

Lodestar 提供两个 profile：`minimal`（默认）和 `full`。schema 是纪律，不是仪式；只有当结构会改变下一步行动时才值得展开。用听起来合理的空话填满字段，正是 minimal profile 要避免的 cargo-cult 失败。

## 轻量 DDD，边界明确

Lodestar 借用 Domain-Driven Design 作为**认知**镜头，而不是软件架构框架。它采用统一语言、限界上下文、核心对象、能力、场景和开放问题，让 agent 把模糊意图翻译成领域模型，从而产出更贴合项目的工作，而不是通用模板。它拒绝战术 DDD：`domain.md` 不暗示代码里需要 repository、aggregate root 或 event sourcing。

## 隐私

项目状态默认本地私有。secret、credential、个人数据和私有 URL 在写入前就应该被脱敏；`.lodestar/` 默认加入 gitignore，除非团队明确选择共享经过审查和脱敏的状态。

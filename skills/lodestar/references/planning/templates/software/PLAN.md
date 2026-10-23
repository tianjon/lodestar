<!-- lodestar-plan: software -->
# <PROJECT> 规划工作区

- 蓝图 blueprint: <这个产品长期要成为什么，一句话>
- 所服务项目 subject: <SUBJECT>
- 当前阶段 phase: <例如：MVP 定义 / 架构选型 / 内测>
- 当前焦点 focus: <本阶段最重要的一件事，与 .lodestar/anchor.md 的 Goal 一致>
- 第一性约束 constraints: <不能违背的基本约束，例如数据安全、单人维护成本、预算、合规>
- 创建 created: <DATE>

这里保存从对话中沉淀下来的规划产物，受版本管理，给人和其他 agent 看。`.lodestar/` 只保存 agent 的定向记忆
（私有、扁平），两者分开。

## 文件地图

| 文件 | 内容 | 编号 |
|---|---|---|
| `ideas.md` | 想法池：所有提出过的可能性及其状态 | `IDEA-001` |
| `roadmap.md` | 阶段与里程碑，每个都有可观察的完成标准 | `MS-001` |
| `decisions.md` | 决策、第一性挑战、用户坚持后的补偿 | `DEC-YYYYMMDD-n` |
| `risks.md` | 风险与待验证假设 | `RISK-001` |
| `domain/glossary.md` | 统一语言 | — |
| `domain/上下文名.md` | 每个限界上下文一个文件（`lodestar new context`） | — |
| `requirements/` | 需求规格，每个需求一个文件，可直接交给其他 agent | `REQ-001` |
| `dashboard.html` | 由 `lodestar dashboard` 生成，勿手改，默认不入库 | — |

## 约定

- 条目一行一个：`- [编号] 标题 | status: … | 字段: …`，细节写在缩进的子项里。
- 编号只增不改。用 `lodestar add` / `lodestar new` 分配编号；不再需要的条目改状态，不删除。
- agent 的补充写成子项 `- 补充(agent): …`，与用户的原意区分开。
- 未决问题写成 `- [ ] Q: …`，解决后改为 `- [x] Q: … → 结论`。

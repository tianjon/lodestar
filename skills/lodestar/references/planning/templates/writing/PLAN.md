<!-- lodestar-plan: writing -->
# <PROJECT> 写作规划

- 蓝图 blueprint: <长期想通过写作达成什么，一句话>
- 读者 audience: <主要写给谁；他们已经知道什么、在乎什么>
- 渠道 channel: <公众号 / 博客 / 期刊 / 内部文档 …>
- 当前阶段 phase: <例如：选题积累 / 系列第一篇>
- 当前焦点 focus: <本阶段最重要的一件事，与 .lodestar/anchor.md 的 Goal 一致>
- 第一性约束 constraints: <不能违背的约束：事实必须有来源、篇幅、发布时间、合规>
- 创建 created: <DATE>

这里保存从对话中沉淀下来的写作规划，受版本管理。`.lodestar/` 只保存 agent 的定向记忆（私有、扁平），两者分开。

## 文件地图

| 文件 | 内容 | 编号 |
|---|---|---|
| `ideas.md` | 选题与素材想法池 | `IDEA-001` |
| `roadmap.md` | 系列与排期 | `MS-001` |
| `pieces/` | 每篇文章一份任务书，可直接交给写作 agent | `PIECE-001` |
| `sources.md` | 资料与引用：文中每个事实都能追到这里 | `SRC-001` |
| `style.md` | 文风与用词，相当于写作的统一语言 | — |
| `decisions.md` | 角度、结构等写作决策，以及第一性挑战 | `DEC-YYYYMMDD-n` |
| `risks.md` | 事实、口径、合规风险 | `RISK-001` |
| `dashboard.html` | 由 `lodestar dashboard` 生成，勿手改，默认不入库 | — |

## 约定

- 条目一行一个：`- [编号] 标题 | status: … | 字段: …`，细节写在缩进的子项里。
- 编号只增不改。用 `lodestar add` / `lodestar new` 分配编号；不再需要的条目改状态，不删除。
- agent 的补充写成子项 `- 补充(agent): …`，与作者的原意区分开。
- 未决问题写成 `- [ ] Q: …`，解决后改为 `- [x] Q: … → 结论`。

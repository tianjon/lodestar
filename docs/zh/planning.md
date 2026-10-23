# 规划层设计

Lodestar 的内核负责让 agent 不跑偏。规划层建立在内核之上，把一段长期的对话沉淀成受版本管理的产物：想法池、
路线图、决策与挑战、风险、领域模型、可以直接交给其他 agent 的规格，以及一个自动生成的 Dashboard。

典型用法：为 `prism-studio` 单独建一个 `prism-studio-docs` 仓库，在里面初始化 Lodestar 与规划工作区，然后像平常一样
和 agent 聊想法和计划。agent 负责记录、建模、补充、提出异议，并在需要时写出交给实现方的需求规格。

## 要解决的问题

| 目标 | 规划层的回答 |
|---|---|
| 正常聊天时持续总结、跟进、结构化想法 | 每条用户消息触发一次简短的回合检查（UserPromptSubmit hook）；想法、决策、风险、术语各自记成一行带编号的条目；思维模型路由表决定用哪种模型来结构化 |
| 同时支持软件工程与写文章 | `software` 与 `writing` 两种工作区模板，共享同一套条目格式、编号规则和工具 |
| 独立的文档仓库服务另一个代码仓库 | `PLAN.md` 的 `subject:` 指向被规划的项目；关于它的判断要以其文件为证据，默认只读 |
| 不符合第一性原理时及时提醒；用户坚持时补偿 | 挑战协议：只提一次，带证据和备选方案；用户坚持则照做，并记录补偿措施与复审条件，之后不再重复争论 |
| 用 HTML Dashboard 展示当前计划 | `lodestar dashboard` 从工作区文件确定性生成单文件 HTML，不由 agent 手写 |
| 为特定功能写出可交给其他 agent 的需求 | `REQ-`/`PIECE-` 规格模板，必须通过"上下文闭包"检查才能标记为 `ready` |

## 设计原则

**记忆与产物分开。** 本仓库的评测发现，由 agent 维护的结构化记忆（树、GAP 台账）在反复重写中会丢条目、弄乱编号，
扁平笔记反而更可靠。规划层并不违背这个结论，因为它把两件事分开了：

| | `.lodestar/` | 规划工作区 |
|---|---|---|
| 用途 | 让 agent 保持方向 | 给人和其他 agent 用的产物 |
| 形态 | 小、扁平、私有（gitignore） | 受版本管理，条目带稳定编号 |
| 维护方式 | 追加日志、更新当前状态 | 逐行增量编辑，从不整体重写 |
| 结构从哪来 | 不需要结构 | 由脚本解析和生成（Dashboard、计数、校验） |

agent 只做它擅长的事：写一行、改一个状态。需要"结构"的地方（统计、看板、引用检查）交给确定性工具。这正是评测
报告里唯一没有被否定的方向："由工具维护的结构"。

**结构服务于下一步行动。** 每个文件、每个字段都要能改变下一次回答、下一份规格或下一个决定，否则就不该存在。
思维模型每回合最多用一两个，只问模型认为缺失的那一个问题。

**用户拥有目标，agent 负责诚实。** 异议只提一次，用证据说话；用户坚持后，agent 的职责从"说服"变成"让这个选择
尽可能成功"。

## 架构

```text
对话 ──► UserPromptSubmit hook（每条消息一次回合检查）
          │  on-track │ 新想法 │ 目标变化 │ 实质冲突
          ▼
      Lodestar 内核（.lodestar/：Anchor、State、Log）── 不跑偏、目标变化诊断
          │
          ▼
      规划工作区（plan/，受版本管理）
          ├── ideas.md        IDEA-  想法池
          ├── roadmap.md      MS-    里程碑
          ├── decisions.md    DEC-   决策、挑战、坚持与补偿
          ├── risks.md        RISK-  风险与假设
          ├── domain/ 或 sources.md + style.md
          └── requirements/ 或 pieces/   REQ- / PIECE- 规格 ──► 其他 agent
          │
          ▼
      lodestar-plan（bash + awk）：add / new / next-id / summary / dashboard / doctor
          │
          ▼
      dashboard.html（生成物，默认不入库）
```

## 工作区

一个目录只要包含首行为 `<!-- lodestar-plan: software -->` 或 `<!-- lodestar-plan: writing -->` 的 `PLAN.md`，
就是规划工作区，默认在 `plan/`。查找顺序：`LODESTAR_PLAN_DIR`、`.lodestar/config` 中的 `plan-dir:`、`plan/`、
项目根目录。

**software**：`PLAN.md`（蓝图、所服务项目、阶段、焦点、第一性约束）、`ideas.md`、`roadmap.md`、`decisions.md`、
`risks.md`、`domain/glossary.md` 与每个限界上下文一个文件、`requirements/`。

**writing**：`PLAN.md`（蓝图、读者、渠道、阶段、焦点、约束）、`ideas.md`、`roadmap.md`、`decisions.md`、`risks.md`、
`sources.md`（证据台账）、`style.md`（写作的统一语言）、`pieces/`。

`.lodestar/domain.md` 在有工作区时只保留关键术语和指向 `domain/` 的说明。Anchor 的 Goal 与 `PLAN.md` 的
`focus:` 应当一致，不一致本身就是目标可能变化的信号。

## 条目格式与编号

```markdown
- [IDEA-007] 多模型对比 | status: exploring | src: 2026-10-23 对话 | next: 明确评分口径
  - 补充(agent): 先确认比较的是答案质量还是成本/延迟，两者的界面完全不同。
  - [ ] Q: 对比结果需要保存和分享吗？
```

- 一行一个条目，字段用 ` | ` 分隔，细节放在缩进子项里。
- 编号：`IDEA-001`、`MS-001`、`RISK-001`、`SRC-001`、`REQ-001`、`PIECE-001`、`DEC-YYYYMMDD-n`。只增不改，
  不再需要时改状态而不是删除。`lodestar add` / `new` / `next-id` 负责分配编号，只统计已定义的条目，所以先写的
  前向引用（例如 `compensation: RISK-001`）不会让编号跳号。
- 未决问题写成 `- [ ] Q: …`，可以出现在任何文件里，Dashboard 会汇总。
- agent 的补充写成 `补充(agent)` 子项，与用户原意分开。
- 状态词表见 `skills/lodestar/references/planning/README.md`。

## 对话循环

每条用户消息，agent 先在心里做一次分类：

1. **在轨**：正常回答。
2. **新想法**：记成一行 `IDEA-`（用用户自己的话，注明来源），可以附一两条非显而易见的补充（边界情况、类似做法、
   风险、更简单的变体），然后回到对话，不被想法带走。探索阶段的新想法是输入，不是跑偏。
3. **目标变化**：用户明确纠正就直接更新 Anchor；只是推断时先确认。
4. **实质冲突**：走挑战协议。
5. **意图模糊**：从思维模型路由表里选一个，只问它认为缺失的那一个问题。

琐碎的回合什么都不写。Stop hook 在一个回合没有保存任何东西时，每隔几个回合补查一次（默认 3 个）。

## 挑战协议

漂移检查问"这件事是否服务于目标"，挑战问"这件事是否站得住"。一个计划可以完全对齐目标，却违背不能弯曲的约束：
成本或时间上限、并不存在的数据、物理与法律、已被证据证明的用户行为、小团队的维护能力。

- **只提一次，简短**：冲突是什么、证据（或注明"证据缺失"）、可能的代价、一个具体的备选方案。可逆的工作不因此
  停下；只有不可逆或破坏性的步骤才等待回答。
- **用户采纳**：记录决策，继续。
- **用户坚持**：完全照做，然后从创新和挑战的角度补偿：
  1. 在决策上记录 `challenge`、`override: user`、`compensation`、`revisit`；
  2. 用最便宜的防护措施对冲主要风险（预留接口、开关、分区键、备份、事实核查）；
  3. 写明能尽早暴露失败的信号，以及触发复审的条件；
  4. 找第三条路：在时间、空间、条件或规模上拆开矛盾，保留用户的意图，同时消除冲突；
  5. 把用户的选择推得更远：它在什么条件下会大获成功？哪一步能让这些条件更可能出现？
  6. 把被否决的方案停放为想法，让以后切换的成本更低。
- **不翻旧账**：被否决过的异议，只有出现新证据或复审条件触发时才重新提起，并引用决策编号。

完整协议：`skills/lodestar/references/challenge.md`。

## 思维模型

路由表按"信号 → 模型 → 写到哪里"组织，涵盖第一性原理、待办任务（JTBD）、优先级、统一语言与限界上下文（轻量 DDD）、
场景与实例映射、故事地图、事前验尸与可逆性、假设地图、TRIZ 分离、最强反方与补偿；写作还有论点与读后效果、
金字塔原理、SCQA、证据台账。见 `skills/lodestar/references/planning/thinking-models.md`。

## 交给其他 agent 的规格

`lodestar new req "标题"`（软件）或 `lodestar new piece "标题"`（写作）从模板创建规格。软件规格包括：背景与目的、
范围（要做与不做）、术语（抄写定义而不是给链接）、场景、需求、逐条对应的验收标准、约束与已定决策、影响范围、
风险与开放问题、实施建议、验证方式、回报要求、"不要做"。写作任务书包括：核心论点、读者与读后效果、角度、
结论先行的结构、论据与来源、反方观点、文风约束、验收标准、回报要求。

标记为 `ready` 之前必须通过**上下文闭包检查**：只拿到这一个文件的 agent，不看对话、不看 `.lodestar/`，也能开始工作，
不需要提问。`lodestar doctor` 会拦下仍有模板占位符或自检项未勾选的 `ready` 规格。

交付后状态改为 `handed-off` 并写明 `owner`；实现方回报后更新状态，把偏差记成决策，把新问题记成开放问题。

## 所服务项目

`PLAN.md` 的 `subject:` 写被规划项目的路径或地址。关于产品现状的判断要以它的文件为证据（引用路径）；默认只读，
用户要求时才修改；如果它也有 `.lodestar/`，可以读来了解实现方的目标和状态，但不写入。

## Dashboard

`lodestar dashboard` 从工作区文件生成单个自包含的 `dashboard.html`（无外部依赖，支持浅色与深色模式），内容包括：
当前焦点（来自 Anchor，可用 `--no-private` 省略）、关键计数、里程碑与其下的规格、规格表、想法看板、决策与挑战
（突出"用户坚持"和复审条件）、开放风险、开放问题、领域模型或资料与文风。它默认加入 `.gitignore`，因为可能包含
私有的 Anchor。agent 在重要变化后重新生成，从不手工编辑。

## Hook 集成

- **SessionStart / SubagentStart**：在原有的 Anchor、Domain、State、Log 摘录之后附上工作区摘要（路径、阶段、焦点、
  各类计数、工具路径）。
- **UserPromptSubmit**：有工作区时，提示把新想法记到 `ideas.md`。
- **Stop**：本回合写过 `.lodestar/` 或工作区就跳过补查。

## 命令

```bash
lodestar init --plan software --subject ../prism-studio --hooks claude   # 或 --plan writing
lodestar add idea "多模型输出对比" src="2026-10-23 对话" next="明确评分口径"
lodestar add dec "先做对比，暂不做权限" challenge="…" override=user compensation=RISK-001 revisit="…"
lodestar new req "模型对比 MVP"
lodestar dashboard            # 生成 plan/dashboard.html
lodestar doctor               # 检查 Anchor 与工作区的不变量
lodestar status               # 包含工作区摘要
```

所有子命令都由 skill 内的 `scripts/lodestar-plan` 实现（bash + POSIX awk，兼容 macOS 自带的 bash 3.2），只装了 skill
的用户也能直接调用它；没有脚本时，每一步也都可以手工完成。

## 刻意不做的事

- 不做数据库或服务：所有状态都是 Markdown 文件。
- 不让 hook 写项目文件：hook 只注入上下文；回合标记只含时间戳和计数，放在项目之外。
- 不自动合并 JSON 配置：无法保证安全时就拒绝，并给出手动合并的方法。
- 不把 DDD 做重：停在统一语言和边界，除非软件架构确实需要更多。

## 如何验证

- `tests/lodestar_cli_test.sh` 与 `tests/contracts_test.py` 覆盖工作区创建、编号分配、条目解析、摘要、Dashboard
  生成与 `doctor`。
- `evals/tasks/planning-conversation/` 定义规划对话评测：想法是否被捕捉、植入的第一性冲突是否被指出、用户坚持后
  是否记录补偿且不再翻旧账、规格是否能让独立 agent 不提问就实现。确定性评分脚本已附带正反两组样例；真实 agent
  对照组尚未运行。

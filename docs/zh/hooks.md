# Hook 行为与兼容边界

Hook 负责投递上下文、请求模型执行检查，不保证目标判断正确或状态保存成功。
脚本本身不会总结会话，也不会写入项目状态。

| 事件 | 行为 |
|---|---|
| SessionStart | 加载有长度上限的 Anchor、Domain、State 和最新的 Log 片段。 |
| UserPromptSubmit | 每条用户消息一次：简短的回合检查（在轨、新想法、目标变化、实质冲突）加 Anchor 摘要；同时开启一个回合，供下面的频率控制使用。 |
| PreToolUse | 在每个回合第一次修改类工具调用之前，提醒检查行动是否对齐，并及时保存重要变化。 |
| SubagentStart | 加载包含领域语言和日志的交接上下文。 |
| SubagentStop | 最多要求子代理续跑一次，补全返回报告。 |
| PostToolUse | 在 Agent/Task/wait/wait_agent 返回后提醒父代理收集已完成的结果；取决于宿主是否暴露相应工具事件。 |
| Stop | 每隔若干个未保存回合最多续跑一次，保存尚未记录的重要变化；状态已是最新时无需重写。 |

Stop 与 SubagentStop 仅在宿主传入 `stop_hook_active: false` 时返回 `decision: block` 和
`reason`；标记为 true 或缺失时返回 `{}`。续跑不是完成性验证器。
除非明确分配了文件所有权，子代理应返回更新建议，由父代理维护共享状态。

**新配置不注册 PreCompact。** 旧入口保留为空操作，以兼容已安装的配置。该事件中的保存指令不会给模型
增加一次压缩前执行保存的机会，因此需要在工作过程中及时记录，并在 Stop 补查。中断仍可能绕过结束检查。

## 回合跟踪与成本

以聊天为主的会话里，旧的 Stop 检查代价很高：每条回复都要多付一次模型续跑，而多数时候只是确认"没有变化"。
安装 UserPromptSubmit 之后：

- **Stop**：本回合已经写过 `.lodestar/`（或规划工作区）时直接跳过；否则每 `LODESTAR_STOP_EVERY` 个未保存回合
  最多检查一次（默认 `3`；设为 `1` 表示每个未保存回合都检查，`0` 表示关闭）。
- **PreToolUse**：每个回合只注入一次漂移检查，而不是每次 Bash/Edit/Write 都注入。
- 没有 UserPromptSubmit 标记时（旧配置、或宿主不支持该事件），两者回退到原行为：Stop 在每次首次停止时检查，
  PreToolUse 在每次匹配的调用前注入。

标记只包含每个会话的时间戳和一个计数，不含任何内容。它们位于项目之外的 `$TMPDIR/lodestar-runtime-<uid>/`
（可用 `LODESTAR_RUNTIME_DIR` 覆盖），两天后清理；所有写入都是尽力而为，沙箱阻止写入时回退到原行为。

## 状态定位与预算

宿主应从会话或项目工作目录运行 hook。脚本向上查找最近的 `.lodestar/`，遇到当前 Git worktree 根目录
即停止；Git 之外查找到文件系统根目录。CLI 的 `init [dir]` 始终在指定目录创建状态。

单文件注入上限为：Anchor 2,000、Domain 1,500、State 3,000、Log 2,000 字符。小文件不再按行截断；
超限的 Anchor、Domain、State 显示首尾，明确标注省略位置、源文件路径，并要求在依赖该状态之前补读。
Log 是追加式的，因此只保留最新的条目，并从完整条目边界开始，同时标注更早历史所在的文件。这不是按语义
选择信息的机制。当前决策宜放在 State 前部；不能假设被省略的信息已经进入模型上下文。64K/128K 的存储预算
保持不变，不代表全部注入。脚本会选择可用的 UTF-8 locale；如果系统没有可用的 UTF-8 locale，超长内容
会省略并提示补读，避免切断多字节字符。

## 安全更新配置

Claude Code 的项目级 hook 默认写入 `.claude/settings.local.json`：生成的命令包含本机绝对路径，而这个文件是
个人配置。`lodestar` 会把它加入 `.gitignore`，已有的共享 `.claude/settings.json` 保持不动。如果某个文件里
已经有 Lodestar 条目，就继续使用该文件，避免重复注册。用户级只有 `~/.claude/settings.json`；该文件已存在时，
请手动合并，或改用 Claude Code 插件安装，插件自带的 `hooks/hooks.json` 无需修改配置文件。

命令中的 Lodestar 标记不代表整个配置文件属于 Lodestar。在不新增运行时 JSON 依赖的前提下，自动安装和
卸载只替换或删除与当前版本生成内容逐字节一致的文件。混合配置、符号链接、重新格式化的配置和旧版配置均
保留。所有目标会在修改前一起预检；`init --hooks` 也会在写入状态文件之前完成预检。不自动合并 JSON。

已有配置可用 `lodestar hooks print` 生成参考，只合并 Lodestar 条目，并保留权限、环境变量和其他 hook。
升级时移除旧 PreCompact 条目，加入 PostToolUse 和 UserPromptSubmit，并对照参考更新其余条目。手动卸载时
只移除命令中含 `LODESTAR_HOOK_MANAGED=1` 的条目以及因此变空的分组。Codex 配置变更后用 `/hooks` 审查并信任。
同一项目避免同时启用插件 hook 与项目 hook，以免重复提醒。

## 接口依据与验证范围

续跑格式依据 [Codex 文档](https://learn.chatgpt.com/docs/hooks)与
[Claude Code 文档](https://code.claude.com/docs/en/hooks#stop-decision-control)。
Claude 的 [PreCompact 接口](https://code.claude.com/docs/en/hooks#precompact)以及面向用户的
`systemMessage` 都不能实现此前声称的模型保存行为。

`tests/contracts_test.py` 会执行生成配置和插件配置中的命令，检查 JSON、续跑保护、配置保留、片段边界、
回合跟踪与 Stop 频率控制。依赖仅用于测试，见 `tests/requirements.txt`。这些测试不等于真实宿主会话端到端
测试；升级宿主时仍需检查实际集成。

# Hook 行为与兼容边界

Hook 负责投递上下文、请求模型执行检查，不保证目标判断正确或状态保存成功。
脚本本身不会总结会话，也不会写入项目状态。

| 事件 | 行为 |
|---|---|
| SessionStart | 加载有长度上限的 Anchor、Domain、State、Log 片段。 |
| PreToolUse | 提醒检查行动是否对齐，并在工作中及时保存重要变化。 |
| SubagentStart | 加载包含领域语言和日志的交接上下文。 |
| SubagentStop | 最多要求子代理续跑一次，补全返回报告。 |
| PostToolUse | 在 Agent/Task/wait/wait_agent 返回后提醒父代理收集已完成的结果；取决于宿主是否暴露相应工具事件。 |
| Stop | 最多续跑一次，保存尚未记录的重要变化；状态已是最新时无需重写。 |

Stop 与 SubagentStop 仅在宿主传入 `stop_hook_active: false` 时返回 `decision: block` 和
`reason`；标记为 true 或缺失时返回 `{}`。每个停止周期最多因此增加一次模型续跑，它不是完成性验证器。
除非明确分配了文件所有权，子代理应返回更新建议，由父代理维护共享状态。

**新配置不注册 PreCompact。** 旧入口保留为空操作，以兼容已安装的配置。该事件中的保存指令不会给模型
增加一次压缩前执行保存的机会，因此需要在工作过程中及时记录，并在 Stop 补查。中断仍可能绕过结束检查。

## 状态定位与预算

宿主应从会话或项目工作目录运行 hook。脚本向上查找最近的 `.lodestar/`，遇到当前 Git worktree 根目录
即停止；Git 之外查找到文件系统根目录。CLI 的 `init [dir]` 始终在指定目录创建状态。

单文件注入上限为：Anchor 2,000、Domain 1,500、State 3,000、Log 1,000 字符。小文件不再按行截断；
超限文件显示首尾，明确标注省略位置、源文件路径，并要求在依赖该状态之前补读。这不是按语义选择信息的机制。
当前决策宜放在前部，最新日志追加在末尾；不能假设被省略的信息已经进入模型上下文。64K/128K 的存储预算
保持不变，不代表全部注入。脚本会选择可用的 UTF-8 locale；如果系统没有可用的 UTF-8 locale，超长内容
会省略并提示补读，避免切断多字节字符。

## 安全更新配置

命令中的 Lodestar 标记不代表整个配置文件属于 Lodestar。在不新增运行时 JSON 依赖的前提下，自动安装和
卸载只替换或删除与当前版本生成内容逐字节一致的文件。混合配置、符号链接、重新格式化的配置和旧版配置均
保留。两个目标会在修改前一起预检，不自动合并 JSON。

已有配置可用 `lodestar hooks print` 生成参考，只合并 Lodestar 条目，并保留权限、环境变量和其他 hook。
升级时移除旧 PreCompact 条目，加入 PostToolUse，并对照参考更新其余条目。手动卸载时只移除命令中含
`LODESTAR_HOOK_MANAGED=1` 的条目以及因此变空的分组。Codex 配置变更后用 `/hooks` 审查并信任。
同一项目避免同时启用插件 hook 与项目 hook，以免重复提醒。

## 接口依据与验证范围

续跑格式依据 [Codex 文档](https://learn.chatgpt.com/docs/hooks)与
[Claude Code 文档](https://code.claude.com/docs/en/hooks#stop-decision-control)。
Claude 的 [PreCompact 接口](https://code.claude.com/docs/en/hooks#precompact)以及面向用户的
`systemMessage` 都不能实现此前声称的模型保存行为。

`tests/contracts_test.py` 会执行生成配置和插件配置中的命令，检查 JSON、续跑保护、配置保留和片段边界。
依赖仅用于测试，见 `tests/requirements.txt`。这些测试不等于真实宿主会话端到端测试；升级宿主时仍需检查实际集成。

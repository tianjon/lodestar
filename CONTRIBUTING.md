# Contributing to Lodestar / 参与 Lodestar

Thanks for helping improve Lodestar. This project is small by design: Markdown protocols, bash
helpers, hook definitions, and documentation.

感谢你帮助改进 Lodestar。本项目刻意保持小核心：Markdown 协议、bash helper、hook 定义和文档。

## Good First Contributions / 适合开始的贡献

- Improve installation instructions for a specific runtime.
- Add a failing test for a CLI or hook edge case.
- Improve bilingual docs.
- Clarify a template field.
- Report where the README was confusing.

- 改进某个运行环境的安装说明。
- 为 CLI 或 hook 边界情况增加失败用例。
- 改进双语文档。
- 澄清模板字段。
- 反馈 README 哪里让人困惑。

## Development / 本地开发

Run the smoke tests:

```bash
bash tests/lodestar_cli_test.sh
```

Run syntax and JSON checks:

```bash
for f in install.sh bin/lodestar hooks/* tests/lodestar_cli_test.sh; do
  [ -f "$f" ] && bash -n "$f"
done
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool hooks/hooks.json >/dev/null
```

## Design Rules / 设计规则

- Keep `.lodestar/` as the only project state namespace.
- Keep the skill self-contained under `skills/lodestar/`.
- Keep hook behavior opt-in, visible, and non-mutating.
- Do not add runtime dependencies unless the benefit is clear and documented.
- Do not store secrets or private project state in examples.

- `.lodestar/` 是唯一项目状态命名空间。
- skill 必须在 `skills/lodestar/` 内保持自包含。
- hook 必须可选、可见、且不静默修改项目文件。
- 除非收益清晰并写入文档，否则不要增加运行时依赖。
- 示例中不要存放密钥或私有项目状态。

## Pull Requests / Pull Request

Please include:

- what changed;
- why it helps users;
- how you tested it.

请包含：

- 改了什么；
- 为什么对用户有帮助；
- 如何验证。

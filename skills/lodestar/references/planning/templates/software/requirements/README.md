# 需求规格

每个需求一个文件：`REQ-001-<slug>.md`，用 `lodestar new req "标题"` 从模板创建。

状态：`draft`（起草中）→ `ready`（自洽、可交付）→ `handed-off`（已交给实现方）→ `in-progress` → `done` · `dropped`。

标记为 `ready` 之前必须通过上下文闭包检查：只拿到这份文件的 agent，不看对话、不看 `.lodestar/`，也能开始工作，
不需要提问。

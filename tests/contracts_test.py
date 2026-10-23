"""Regression tests for state delivery, config ownership, and evaluation contracts."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]


def run(*args, cwd=ROOT, payload=None, check=True, env=None):
    return subprocess.run([str(a) for a in args], cwd=cwd, input=payload,
                          text=True, capture_output=True, check=check, env=env)


class Contracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lodestar-contract-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.env = dict(os.environ, LODESTAR_RUNTIME_DIR=str(self.base / "runtime"))

    def init(self, path=None, hooks="none"):
        path = path or self.base / "project"
        run(ROOT / "bin/lodestar", "init", path, "--hooks", hooks)
        return path

    def hook(self, name, project, data=None, env=None):
        return run(ROOT / "hooks" / name, cwd=project,
                   payload=json.dumps(data or {}), env=env or self.env).stdout

    def context(self, name, project, data=None, env=None):
        out = self.hook(name, project, data, env)
        return json.loads(out)["hookSpecificOutput"]["additionalContext"] if out.strip() else ""

    def backdate_turn(self, session):
        # Make the turn marker strictly older than later writes on coarse-mtime filesystems.
        for marker in (self.base / "runtime").glob(f"*/{session}.turn"):
            old = time.time() - 30
            os.utime(marker, (old, old))

    def test_frontmatter_parses_as_a_skill(self):
        front = (ROOT / "skills/lodestar/SKILL.md").read_text().split("---", 2)[1]
        data = yaml.safe_load(front)
        self.assertEqual(data["name"], "lodestar")
        self.assertIsInstance(data["description"], str)
        self.assertIn("Triggers:", data["description"])

    def test_mixed_settings_survive_install_and_uninstall_without_partial_changes(self):
        project = self.init(hooks="both")
        claude = project / ".claude/settings.local.json"
        codex = project / ".codex/hooks.json"
        data = json.loads(claude.read_text())
        data.update(permissions={"deny": ["Bash(example)"]}, env={"KEEP": "yes"})
        data["hooks"]["Stop"].append({"hooks": [{"type": "command", "command": "echo keep"}]})
        claude.write_text(json.dumps(data))
        expected = {p: p.read_bytes() for p in (claude, codex)}
        for action in ("install", "uninstall"):
            result = run(ROOT / "bin/lodestar", "hooks", action, project, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("lodestar hooks print", result.stderr)
            for path, contents in expected.items():
                self.assertEqual(path.read_bytes(), contents)

    def test_symlink_settings_are_never_overwritten_or_removed(self):
        project = self.init()
        external = self.base / "settings.json"
        external.write_text(run(ROOT / "bin/lodestar", "hooks", "print").stdout)
        (project / ".claude").mkdir()
        settings = project / ".claude/settings.json"
        settings.symlink_to(external)
        before = external.read_bytes()
        for action in ("install", "uninstall"):
            result = run(ROOT / "bin/lodestar", "hooks", action, project,
                         "--target", "claude", check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(settings.is_symlink())
            self.assertEqual(external.read_bytes(), before)

    def test_nearest_project_wins_inside_a_monorepo(self):
        parent = self.init(self.base / "repo")
        run("git", "init", "-q", parent)
        child = self.init(parent / "packages/app")
        (parent / ".lodestar/anchor.md").write_text("PARENT_ONLY")
        (child / ".lodestar/anchor.md").write_text("CHILD_ONLY")
        nested = child / "src"
        nested.mkdir()
        result = self.hook("session-start", nested)
        self.assertIn("CHILD_ONLY", result)
        self.assertNotIn("PARENT_ONLY", result)

    def test_non_git_parent_discovery_and_git_boundary(self):
        parent = self.init()
        nested = parent / "src"
        nested.mkdir()
        self.assertIn("LODESTAR_CONTEXT", self.hook("session-start", nested))
        run("git", "init", "-q", nested)
        self.assertIn("not initialized", self.hook("session-start", nested))

    def test_small_many_line_state_is_delivered_in_full(self):
        project = self.init()
        state = "\n".join(["fact"] * 100 + ["LAST_DECISION"])
        (project / ".lodestar/state.md").write_text(state)
        (project / ".lodestar/domain.md").write_text("DOMAIN_SENTINEL")
        (project / ".lodestar/log.md").write_text("RECENT_DECISION")
        for event in ("session-start", "subagent-start"):
            result = self.hook(event, project)
            for value in ("LAST_DECISION", "DOMAIN_SENTINEL", "RECENT_DECISION"):
                self.assertIn(value, result)

    def test_large_excerpts_are_bounded_and_explicit(self):
        project = self.init()
        for name in ("anchor", "domain", "state", "log"):
            (project / f".lodestar/{name}.md").write_text("HEAD_" + name + "汉" * 20000 + "TAIL_" + name)
        for event in ("session-start", "subagent-start"):
            context = self.context(event, project, env=dict(self.env, LC_ALL="C"))
            self.assertLess(len(context), 12000)
            for name in ("anchor", "domain", "state", "log"):
                self.assertIn("TAIL_" + name, context)
                self.assertIn(str(project / f".lodestar/{name}.md"), context)
            for name in ("anchor", "domain", "state"):
                self.assertIn("HEAD_" + name, context)
            # The log is an append-only stream: its newest entries matter, not its header.
            self.assertNotIn("HEAD_log", context)
            self.assertIn("TRUNCATED", context)
            self.assertIn("EARLIER ENTRIES OMITTED", context)

    def test_log_excerpt_keeps_newest_entries_from_entry_boundary(self):
        project = self.init()
        log = project / ".lodestar/log.md"
        entries = "".join(f"\n## 2026-10-{i:02d}T10:00:00Z | imp:0.5 | facets:[Decision]\n- source: 决定第{i}件事" + "细" * 120 + "\n"
                          for i in range(1, 21))
        log.write_text(log.read_text() + entries)
        context = self.context("session-start", project)
        self.assertIn("决定第20件事", context)
        self.assertNotIn("Entry template", context)
        tail = context.split("EARLIER ENTRIES OMITTED", 1)[1]
        self.assertTrue(tail.split("\n", 1)[1].startswith("## 2026-10-"), tail[:200])

    def test_user_prompt_submit_marks_turn_and_carries_orientation(self):
        project = self.init()
        context = self.context("user-prompt-submit", project, {"session_id": "s1", "prompt": "hi"})
        self.assertIn("LODESTAR_TURN", context)
        self.assertIn("Goal", context)
        self.assertIn("re-litigate", context)
        self.assertLess(len(context), 1600)
        self.assertTrue(list((self.base / "runtime").glob("*/s1.turn")))
        outside = self.base / "outside"
        outside.mkdir()
        run("git", "init", "-q", outside)
        self.assertEqual(self.hook("user-prompt-submit", outside, {"session_id": "s1"}), "")

    def test_pretool_drift_check_runs_once_per_tracked_turn(self):
        project = self.init()
        call = {"session_id": "s1", "tool_name": "Write"}
        self.assertIn("LODESTAR_DRIFT_CHECK", self.context("pre-tool-use", project, call))
        self.assertIn("LODESTAR_DRIFT_CHECK", self.context("pre-tool-use", project, call))
        self.hook("user-prompt-submit", project, {"session_id": "s1"})
        self.assertIn("LODESTAR_DRIFT_CHECK", self.context("pre-tool-use", project, call))
        self.assertEqual(self.hook("pre-tool-use", project, call), "")
        self.backdate_turn("s1")
        self.hook("user-prompt-submit", project, {"session_id": "s1"})
        self.assertIn("LODESTAR_DRIFT_CHECK", self.context("pre-tool-use", project, call))

    def test_stop_gate_rate_limits_unsaved_turns_and_skips_saved_turns(self):
        project = self.init()
        stop = {"session_id": "s1", "stop_hook_active": False}

        def turn():
            self.hook("user-prompt-submit", project, {"session_id": "s1"})
            return json.loads(self.hook("stop", project, stop))

        self.assertEqual(turn(), {})
        self.assertEqual(turn(), {})
        self.assertEqual(turn()["decision"], "block")
        self.assertEqual(json.loads(self.hook("stop", project, dict(stop, stop_hook_active=True))), {})
        self.assertEqual(turn(), {})
        self.assertEqual(turn(), {})
        self.hook("user-prompt-submit", project, {"session_id": "s1"})
        self.backdate_turn("s1")
        log = project / ".lodestar/log.md"
        log.write_text(log.read_text() + "\n## saved\n")
        self.assertEqual(json.loads(self.hook("stop", project, stop)), {})
        self.assertEqual(turn(), {})
        every_turn = dict(self.env, LODESTAR_STOP_EVERY="1")
        self.hook("user-prompt-submit", project, {"session_id": "s1"}, env=every_turn)
        self.assertEqual(json.loads(self.hook("stop", project, stop, env=every_turn))["decision"], "block")
        never = dict(self.env, LODESTAR_STOP_EVERY="0")
        self.assertEqual(json.loads(self.hook("stop", project, {"session_id": "fresh", "stop_hook_active": False}, env=never)), {})

    def plan_project(self, profile="software"):
        project = self.base / f"plan-{profile}"
        run(ROOT / "bin/lodestar", "init", project, "--plan", profile, "--subject", "../subject")
        return project

    def test_hooks_carry_planning_workspace_summary(self):
        project = self.plan_project()
        tool = ROOT / "bin/lodestar"
        run(tool, "add", "idea", "多模型对比", "--root", project)
        run(tool, "add", "dec", "先做对比", "override=user", "compensation=RISK-001", "--root", project)
        (project / "plan/ideas.md").write_text((project / "plan/ideas.md").read_text()
                                               + "  - [ ] Q: 需要保存对比结果吗？\n")
        for event in ("session-start", "subagent-start"):
            context = self.context(event, project)
            self.assertIn("PLANNING WORKSPACE (plan/, profile software, subject ../subject)", context)
            self.assertIn("Ideas: 1 inbox", context)
            self.assertIn("Open questions: 1", context)
            self.assertIn("Decisions: 1 (1 user override)", context)
            self.assertIn("scripts/lodestar-plan", context)
        turn = self.context("user-prompt-submit", project, {"session_id": "p"})
        self.assertIn("plan/ideas.md", turn)

    def test_summary_ignores_template_examples_and_placeholders(self):
        project = self.plan_project()
        run(ROOT / "bin/lodestar", "new", "req", "Compare", "--root", project)
        summary = run(ROOT / "bin/lodestar", "summary", "--root", project).stdout
        # Template examples live in comments; spec placeholders such as "Q: <…>" are not questions.
        self.assertIn("Ideas: none | Specs: 1 draft | Open questions: 0 | Open risks: 0 | Decisions: 0", summary)

    def test_stop_skips_when_the_turn_wrote_the_workspace(self):
        project = self.plan_project()
        stop = {"session_id": "w", "stop_hook_active": False}
        env = dict(self.env, LODESTAR_STOP_EVERY="1")
        self.hook("user-prompt-submit", project, {"session_id": "w"}, env=env)
        self.backdate_turn("w")
        ideas = project / "plan/ideas.md"
        ideas.write_text(ideas.read_text() + "- [IDEA-001] x | status: inbox\n")
        self.assertEqual(json.loads(self.hook("stop", project, stop, env=env)), {})
        self.hook("user-prompt-submit", project, {"session_id": "w"}, env=env)
        self.assertEqual(json.loads(self.hook("stop", project, stop, env=env))["decision"], "block")

    def fill_anchor(self, project, goal="确定 MVP 范围", done="REQ-001 ready"):
        anchor = project / ".lodestar/anchor.md"
        text = anchor.read_text(encoding="utf-8")
        text = text.replace("<the ONE active objective right now — a single sentence>", goal)
        text = text.replace("<observable acceptance criteria>", done)
        text = text.replace("<ISO timestamp> — on-track", time.strftime("%Y-%m-%d") + " — on-track")
        anchor.write_text(text, encoding="utf-8")

    def test_dashboard_renders_escaped_self_contained_html(self):
        import html.parser

        class Balance(html.parser.HTMLParser):
            void = {"meta", "br", "img", "input", "link", "hr"}

            def __init__(self):
                super().__init__()
                self.stack, self.errors = [], []

            def handle_starttag(self, tag, attrs):
                if tag not in self.void:
                    self.stack.append(tag)

            def handle_endtag(self, tag):
                if self.stack and self.stack[-1] == tag:
                    self.stack.pop()
                else:
                    self.errors.append(tag)

        project = self.plan_project()
        self.fill_anchor(project, goal="SECRET_GOAL <b>")
        tool = ROOT / "bin/lodestar"
        run(tool, "add", "ms", "MVP", "status=active", "--root", project)
        run(tool, "add", "idea", "<script>alert(1)</script>", "--root", project)
        run(tool, "add", "dec", "先做对比", "override=user", "challenge=隔离是约束",
            "compensation=RISK-001", "revisit=外部用户前", "--root", project)
        run(tool, "add", "risk", "数据混用", "impact=high", "--root", project)
        ideas = project / "plan/ideas.md"
        ideas.write_text(ideas.read_text(encoding="utf-8") + "  - 补充(agent): AGENT_NOTE\n  - [ ] Q: OPEN_Q?\n", encoding="utf-8")
        spec = Path(run(tool, "new", "req", "Compare", "--root", project).stdout.strip())
        spec.write_text(spec.read_text(encoding="utf-8").replace("<MS 编号>", "MS-001").replace("- status: draft", "- status: done"), encoding="utf-8")

        out = Path(run(tool, "dashboard", "--root", project).stdout.strip())
        self.assertEqual(out, (project / "plan/dashboard.html").resolve())
        page = out.read_text(encoding="utf-8")
        checker = Balance()
        checker.feed(page)
        self.assertEqual((checker.stack, checker.errors), ([], []))
        self.assertNotIn("<script>alert", page)
        self.assertIn("&lt;script&gt;alert(1)&lt;/script&gt;", page)
        self.assertIn("SECRET_GOAL &lt;b&gt;", page)
        for text in ("IDEA-001", "AGENT_NOTE", "OPEN_Q?", "用户坚持", "外部用户前", "REQ-001", "1 / 1", 'href="ideas.md"',
                     "prefers-color-scheme: dark", 'data-theme="dark"'):
            self.assertIn(text, page)
        self.assertNotIn("http://", page.replace("http://www.w3.org", ""))
        self.assertNotIn("https://", page)

        private_free = self.base / "share/dash.html"
        run(tool, "dashboard", "--root", project, "--no-private", "--lang", "en", "--out", private_free)
        shared = private_free.read_text(encoding="utf-8")
        self.assertNotIn("SECRET_GOAL", shared)
        self.assertIn("Idea board", shared)
        self.assertIn("file://" + str((project / "plan").resolve()) + "/ideas.md", shared)

    def test_doctor_turns_invariants_into_exit_status(self):
        project = self.plan_project()
        tool = ROOT / "bin/lodestar"
        fresh = run(tool, "doctor", "--root", project, check=False)
        self.assertEqual(fresh.returncode, 1)
        self.assertIn("FAIL  Anchor Goal is empty", fresh.stdout)
        self.fill_anchor(project)
        healthy = run(tool, "doctor", "--root", project, check=False)
        self.assertEqual(healthy.returncode, 0, healthy.stdout)
        self.assertIn("ok    Anchor Drift check dated", healthy.stdout)

        run(tool, "add", "dec", "坚持", "override=user", "--root", project)
        ideas = project / "plan/ideas.md"
        ideas.write_text(ideas.read_text(encoding="utf-8") + "- [IDEA-001] a | status: inbox\n- [IDEA-001] b | status: someday\n", encoding="utf-8")
        spec = Path(run(tool, "new", "req", "Ready too early", "--root", project).stdout.strip())
        spec.write_text(spec.read_text(encoding="utf-8").replace("- status: draft", "- status: ready"), encoding="utf-8")
        broken = run(tool, "doctor", "--root", project, check=False)
        self.assertEqual(broken.returncode, 1)
        for text in ("FAIL  duplicate ID IDEA-001", "unknown status \"someday\"", "without compensation",
                     "without a revisit trigger", "template placeholder", "unticked context-closure"):
            self.assertIn(text, broken.stdout)

    def test_planning_eval_scorer_and_driver(self):
        task = ROOT / "evals/tasks/planning-conversation"
        smoke = run("bash", task / "run_smoke.sh")
        self.assertIn("ok - planning-conversation scorer separates the fixtures", smoke.stdout)
        out = self.base / "planning-eval"
        run("bash", task / "run_agent.sh", "--agent-cmd", "cat > /dev/null; echo ok", "--out", out)
        rows = [json.loads(line) for line in (out / "results.jsonl").read_text().splitlines()]
        self.assertEqual([r["arm"] for r in rows], ["A", "B", "C"])
        self.assertTrue(all(r["result"]["score"] < 40 for r in rows))
        b_prompt = (out / "B/seed-1/transcripts/03.prompt.txt").read_text(encoding="utf-8")
        self.assertIn("<LODESTAR_CONTEXT>", b_prompt)
        self.assertIn("<LODESTAR_TURN>", b_prompt)
        self.assertIn("PLANNING WORKSPACE", b_prompt)
        a_prompt = (out / "A/seed-1/transcripts/03.prompt.txt").read_text(encoding="utf-8")
        self.assertNotIn("LODESTAR", a_prompt)
        self.assertIn("API key", a_prompt)

    def test_stop_feedback_requests_only_one_continuation(self):
        project = self.init()
        before = {p: p.read_bytes() for p in (project / ".lodestar").glob("*.md")}
        for event in ("stop", "subagent-stop"):
            data = json.loads(self.hook(event, project, {"stop_hook_active": False}))
            self.assertEqual(data["decision"], "block")
            self.assertTrue(data["reason"])
            self.assertNotIn("systemMessage", data)
            for payload in ({"stop_hook_active": True}, {},
                            {"last_assistant_message": ', "stop_hook_active":false,'}):
                self.assertEqual(json.loads(self.hook(event, project, payload)), {})
        self.assertEqual(self.hook("pre-compact", project), "")
        result = json.loads(self.hook("post-tool-use", project))
        self.assertEqual(result["hookSpecificOutput"]["hookEventName"], "PostToolUse")
        self.assertIn("parent", result["hookSpecificOutput"]["additionalContext"])
        self.assertEqual({p: p.read_bytes() for p in before}, before)

    def test_generated_and_plugin_commands_deliver_the_same_event_contract(self):
        project = self.init(self.base / "project with 'quote", hooks="both")
        configs = [json.loads((project / ".codex/hooks.json").read_text()),
                   json.loads((project / ".claude/settings.local.json").read_text()),
                   json.loads((ROOT / "hooks/hooks.json").read_text())]
        for index, config in enumerate(configs):
            self.assertNotIn("PreCompact", config["hooks"])
            self.assertIn("PostToolUse", config["hooks"])
            self.assertIn("UserPromptSubmit", config["hooks"])
            for event, groups in config["hooks"].items():
                cmd = groups[0]["hooks"][0]["command"]
                env = dict(os.environ, PLUGIN_ROOT=str(ROOT), CLAUDE_PLUGIN_ROOT=str(ROOT),
                           LODESTAR_RUNTIME_DIR=str(self.base / f"runtime-{index}"),
                           LODESTAR_STOP_EVERY="1")
                result = run("sh", "-c", cmd, cwd=project, env=env,
                             payload=json.dumps({"hook_event_name": event, "stop_hook_active": False}))
                data = json.loads(result.stdout)
                if event in ("Stop", "SubagentStop"):
                    self.assertEqual(data["decision"], "block")
                else:
                    self.assertEqual(data["hookSpecificOutput"]["hookEventName"], event)

    def test_eval_injects_both_arms_and_records_failures(self):
        out = self.base / "eval"
        run("bash", ROOT / "evals/run.sh", "--arms", "B,C", "--iters", "2",
            "--agent", "exit 7", "--out", out)
        for arm in ("B", "C"):
            project = out / f"work/{arm}/seed-1"
            self.assertFalse((project / ".claude/settings.json").exists())
            self.assertFalse((project / ".codex/hooks.json").exists())
            for turn in (1, 2):
                artifacts = out / f"artifacts/{arm}/seed-1"
                text = (artifacts / f"{turn}.orientation.txt").read_text()
                self.assertIn("Prepare release", text)
                self.assertIn(text, (artifacts / f"{turn}.prompt.txt").read_text())
                self.assertEqual(int((artifacts / f"{turn}.orientation.bytes").read_text()), len(text.encode()))
                self.assertEqual((artifacts / f"{turn}.exit-code").read_text().strip(), "7")
        results = [json.loads(line) for line in (out / "results.jsonl").read_text().splitlines()]
        self.assertEqual([r["failed_iterations"] for r in results], [2, 2])


if __name__ == "__main__":
    unittest.main()

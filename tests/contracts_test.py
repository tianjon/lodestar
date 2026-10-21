"""Regression tests for state delivery, config ownership, and evaluation contracts."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
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

    def init(self, path=None, hooks="none"):
        path = path or self.base / "project"
        run(ROOT / "bin/lodestar", "init", path, "--hooks", hooks)
        return path

    def hook(self, name, project, data=None, env=None):
        return run(ROOT / "hooks" / name, cwd=project,
                   payload=json.dumps(data or {}), env=env).stdout

    def test_frontmatter_parses_as_a_skill(self):
        front = (ROOT / "skills/lodestar/SKILL.md").read_text().split("---", 2)[1]
        data = yaml.safe_load(front)
        self.assertEqual(data["name"], "lodestar")
        self.assertIsInstance(data["description"], str)
        self.assertIn("Triggers:", data["description"])

    def test_mixed_settings_survive_install_and_uninstall_without_partial_changes(self):
        project = self.init(hooks="both")
        claude = project / ".claude/settings.json"
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
            context = json.loads(self.hook(event, project, env=dict(os.environ, LC_ALL="C")))["hookSpecificOutput"]["additionalContext"]
            self.assertLess(len(context), 10000)
            for name in ("anchor", "domain", "state", "log"):
                self.assertIn("HEAD_" + name, context)
                self.assertIn("TAIL_" + name, context)
                self.assertIn(str(project / f".lodestar/{name}.md"), context)
            self.assertIn("TRUNCATED", context)

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
                   json.loads((project / ".claude/settings.json").read_text()),
                   json.loads((ROOT / "hooks/hooks.json").read_text())]
        for config in configs:
            self.assertNotIn("PreCompact", config["hooks"])
            self.assertIn("PostToolUse", config["hooks"])
            for event, groups in config["hooks"].items():
                cmd = groups[0]["hooks"][0]["command"]
                env = dict(os.environ, PLUGIN_ROOT=str(ROOT), CLAUDE_PLUGIN_ROOT=str(ROOT))
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

#!/usr/bin/env python3
"""Isolated tests for bin/agentctl.

Every test gets a temporary HOME and never reads or writes the real agent
configuration. Native plugin CLIs are replaced by small mock executables.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
AGENTCTL = REPO / "bin" / "agentctl"


class AgentctlTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory(prefix="agentctl-test-")
        self.root = Path(self.tmp.name)
        self.home = self.root / "home"
        self.mock_bin = self.root / "mock-bin"
        self.home.mkdir()
        self.mock_bin.mkdir()
        for rel in (
            ".claude/skills",
            ".codex/skills",
            ".config/opencode/skills",
            ".gemini/config",
            ".local/bin",
        ):
            (self.home / rel).mkdir(parents=True, exist_ok=True)
        (self.home / ".gemini/config/skills.json").write_text(
            json.dumps({"entries": [{"path": "~/.agents/skills"}]}),
            encoding="utf-8",
        )
        self.mock_log = self.root / "mock-cli.log"
        self.env = os.environ.copy()
        self.env.update(
            {
                "HOME": str(self.home),
                "PATH": str(self.mock_bin) + os.pathsep + self.env.get("PATH", ""),
                "MOCK_LOG": str(self.mock_log),
                "GIT_AUTHOR_NAME": "agentctl-test",
                "GIT_AUTHOR_EMAIL": "agentctl-test@example.invalid",
                "GIT_COMMITTER_NAME": "agentctl-test",
                "GIT_COMMITTER_EMAIL": "agentctl-test@example.invalid",
            }
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def run_cli(self, *args: str, env: dict | None = None, check: bool = True):
        merged = self.env.copy()
        if env:
            merged.update(env)
        proc = subprocess.run(
            [sys.executable, str(AGENTCTL), *args],
            cwd=self.root,
            env=merged,
            text=True,
            capture_output=True,
            timeout=120,
        )
        if check and proc.returncode != 0:
            self.fail(
                f"agentctl {' '.join(args)} failed with {proc.returncode}\n"
                f"stdout:\n{proc.stdout}\nstderr:\n{proc.stderr}"
            )
        return proc

    def make_skill(self, name: str = "demo", body: str = "v1") -> Path:
        src = self.root / "sources" / name
        src.mkdir(parents=True, exist_ok=True)
        (src / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: test skill\n---\n\n{body}\n",
            encoding="utf-8",
        )
        (src / "notes.txt").write_text(f"notes {body}\n", encoding="utf-8")
        return src

    def write_mock_cli(self, name: str, list_payload: object | None = None) -> None:
        script = self.mock_bin / name
        payload = repr(list_payload) if list_payload is not None else "None"
        script.write_text(
            f"""#!{sys.executable}
import json
import os
import sys

args = sys.argv[1:]
with open(os.environ["MOCK_LOG"], "a", encoding="utf-8") as fh:
    fh.write("{name} " + " ".join(args) + "\\n")

list_payload = {payload}
if args[:3] == ["plugin", "list", "--json"]:
    print(json.dumps(list_payload) if list_payload is not None else "")
    sys.exit(0)
if args[:3] == ["plugin", "marketplace", "list"]:
    print(json.dumps({{"marketplaces": []}}))
    sys.exit(0)
print(json.dumps({{"ok": True}}))
""",
            encoding="utf-8",
        )
        script.chmod(0o755)

    def inode(self, path: Path) -> int:
        return path.stat().st_ino

    def assert_hardlinked(self, canonical: Path, projection: Path) -> None:
        self.assertTrue(projection.is_dir(), projection)
        for rel in ("SKILL.md", "notes.txt"):
            self.assertEqual(
                self.inode(canonical / rel),
                self.inode(projection / rel),
                f"{projection / rel} is not a hardlink of {canonical / rel}",
            )

    def test_install_creates_one_canonical_copy_and_hardlinks(self) -> None:
        src = self.make_skill()
        self.run_cli("install", str(src), "--name", "demo", "--agent", "claude,codex,opencode")

        canonical = self.home / ".agents/skills/demo"
        self.assertTrue((canonical / "SKILL.md").is_file())
        projections = {
            "claude": self.home / ".claude/skills/demo",
            "codex": self.home / ".codex/skills/demo",
            "opencode": self.home / ".config/opencode/skills/demo",
        }
        for projection in projections.values():
            self.assert_hardlinked(canonical, projection)

        status = json.loads(self.run_cli("status", "--json").stdout)
        self.assertEqual(status["canonical_count"], 1)
        self.assertEqual(status["duplicates"], [])
        self.assertEqual(status["agents"]["claude"]["links"], 1)
        self.assertEqual(status["agents"]["claude"]["dirs"], 0)

    def test_gemini_is_a_canonical_consumer_not_a_projection(self) -> None:
        src = self.make_skill()
        self.run_cli("install", str(src), "--name", "demo", "--agent", "all")
        self.assertFalse((self.home / ".gemini/config/skills/demo").exists())
        status = json.loads(self.run_cli("status", "--json").stdout)
        self.assertIn("gemini", status["consumers"])

    def test_disable_only_removes_the_selected_projection(self) -> None:
        src = self.make_skill()
        self.run_cli("install", str(src), "--name", "demo", "--agent", "claude,codex")
        self.run_cli("disable", "demo", "--agent", "claude")

        self.assertFalse((self.home / ".claude/skills/demo").exists())
        self.assertTrue((self.home / ".codex/skills/demo/SKILL.md").is_file())
        self.assertTrue((self.home / ".agents/skills/demo/SKILL.md").is_file())

    def test_git_update_propagates_through_existing_hardlinks(self) -> None:
        work = self.root / "work"
        work.mkdir()
        (work / "SKILL.md").write_text("---\nname: demo\ndescription: v1\n---\n\nv1\n", encoding="utf-8")
        (work / "notes.txt").write_text("v1\n", encoding="utf-8")
        for cmd in (
            ["git", "init", "-b", "main"],
            ["git", "add", "."],
            ["git", "commit", "-m", "v1"],
        ):
            subprocess.run(cmd, cwd=work, env=self.env, check=True, capture_output=True)
        bare = self.root / "remote.git"
        subprocess.run(["git", "clone", "--bare", str(work), str(bare)], env=self.env, check=True, capture_output=True)

        self.run_cli("install", str(bare), "--name", "demo", "--agent", "claude,codex")
        canonical = self.home / ".agents/skills/demo"
        old_inode = self.inode(canonical / "SKILL.md")

        (work / "SKILL.md").write_text("---\nname: demo\ndescription: v2\n---\n\nv2\n", encoding="utf-8")
        (work / "notes.txt").write_text("v2\n", encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=work, env=self.env, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "v2"], cwd=work, env=self.env, check=True, capture_output=True)
        subprocess.run(["git", "push", str(bare), "main"], cwd=work, env=self.env, check=True, capture_output=True)

        self.run_cli("update", "demo")
        self.assertIn("v2", (canonical / "SKILL.md").read_text(encoding="utf-8"))
        self.assertIn("v2", (self.home / ".claude/skills/demo/SKILL.md").read_text(encoding="utf-8"))
        self.assertIn("v2", (self.home / ".codex/skills/demo/SKILL.md").read_text(encoding="utf-8"))
        self.assertEqual(old_inode, self.inode(canonical / "SKILL.md"))

    def test_remove_is_dry_run_by_default_then_moves_to_trash(self) -> None:
        src = self.make_skill()
        self.run_cli("install", str(src), "--name", "demo", "--agent", "claude,codex")
        canonical = self.home / ".agents/skills/demo"

        dry = self.run_cli("remove", "demo")
        self.assertIn("DRY-RUN", dry.stdout)
        self.assertTrue(canonical.is_dir())

        self.run_cli("remove", "demo", "--apply")
        self.assertFalse(canonical.exists())
        self.assertFalse((self.home / ".claude/skills/demo").exists())
        self.assertFalse((self.home / ".codex/skills/demo").exists())
        self.assertTrue(any((self.home / ".agents/agentctl/trash").iterdir()))

    def test_adopt_converges_an_existing_agent_copy(self) -> None:
        copy = self.home / ".claude/skills/demo"
        copy.mkdir(parents=True)
        (copy / "SKILL.md").write_text("---\nname: demo\ndescription: local\n---\n\nlocal\n", encoding="utf-8")
        (copy / "notes.txt").write_text("local\n", encoding="utf-8")

        dry = self.run_cli("adopt")
        self.assertIn("DRY-RUN", dry.stdout)
        self.assertTrue(copy.is_dir())
        self.assertFalse((self.home / ".agents/skills/demo").exists())

        self.run_cli("adopt", "--apply")
        canonical = self.home / ".agents/skills/demo"
        self.assert_hardlinked(canonical, copy)

    def test_mcp_merge_keeps_handwritten_claude_entry(self) -> None:
        claude_json = self.home / ".claude.json"
        claude_json.write_text(
            json.dumps({"theme": "dark", "mcpServers": {"handwritten": {"command": "echo"}}}),
            encoding="utf-8",
        )
        spec = json.dumps({"command": "npx", "args": ["-y", "some-mcp"]})
        self.run_cli("mcp", "add", "demo", spec, "--agent", "claude", "--apply")

        data = json.loads(claude_json.read_text(encoding="utf-8"))
        self.assertEqual(data["theme"], "dark")
        self.assertEqual(data["mcpServers"]["handwritten"]["command"], "echo")
        self.assertEqual(data["mcpServers"]["demo"]["command"], "npx")

    def test_mcp_codex_block_preserves_handwritten_entry(self) -> None:
        config = self.home / ".codex/config.toml"
        config.write_text('[mcp_servers.handwritten]\ncommand = "echo"\n', encoding="utf-8")
        spec = json.dumps({"command": "npx", "args": ["-y", "some-mcp"]})
        self.run_cli("mcp", "add", "demo", spec, "--agent", "codex", "--apply")

        import tomllib

        data = tomllib.loads(config.read_text(encoding="utf-8"))
        self.assertEqual(data["mcp_servers"]["handwritten"]["command"], "echo")
        self.assertEqual(data["mcp_servers"]["demo"]["command"], "npx")
        self.assertIn("# >>> agentctl:mcp >>>", config.read_text(encoding="utf-8"))

    def test_mcp_secret_is_masked_in_registry_and_resolved_on_sync(self) -> None:
        spec = json.dumps({"command": "secret-server", "env": {"API_TOKEN": "plaintext-value"}})
        self.run_cli("mcp", "add", "secret", spec, "--agent", "claude")
        registry_text = (self.home / ".agents/agentctl/mcp.json").read_text(encoding="utf-8")
        registry = json.loads(registry_text)
        self.assertEqual(registry["servers"]["secret"]["spec"]["env"]["API_TOKEN"], "${API_TOKEN}")
        self.assertNotIn("plaintext-value", registry_text)

        self.run_cli("mcp", "sync", "--agent", "claude", env={"API_TOKEN": "from-environment"})
        data = json.loads((self.home / ".claude.json").read_text(encoding="utf-8"))
        self.assertEqual(data["mcpServers"]["secret"]["env"]["API_TOKEN"], "from-environment")

    def test_doctor_accepts_cc_switch_symlink_into_unified_store(self) -> None:
        settings = self.home / ".cc-switch/settings.json"
        settings.parent.mkdir(parents=True)
        settings.write_text(
            json.dumps({"skillSyncMethod": "symlink", "skillStorageLocation": "unified"}),
            encoding="utf-8",
        )

        data = json.loads(self.run_cli("doctor", "--json").stdout)
        kinds = {item["kind"] for item in data["problems"]}
        self.assertNotIn("cc-switch-skill-sync", kinds)
        self.assertIn("note", kinds)

        settings.write_text(
            json.dumps({"skillSyncMethod": "auto", "skillStorageLocation": "unified"}),
            encoding="utf-8",
        )
        data = json.loads(self.run_cli("doctor", "--json").stdout)
        kinds = {item["kind"] for item in data["problems"]}
        self.assertIn("cc-switch-skill-sync", kinds)

    def test_plugin_list_parses_claude_and_codex_json(self) -> None:
        (self.home / ".claude/settings.json").write_text("{}", encoding="utf-8")
        (self.home / ".codex/config.toml").write_text("", encoding="utf-8")
        self.write_mock_cli(
            "claude",
            [{"id": "foo@market", "enabled": True, "installPath": "/tmp/foo", "version": "1.2"}],
        )
        self.write_mock_cli(
            "codex",
            {"installed": [{"pluginId": "bar@market", "enabled": True, "version": "2.0"}]},
        )

        data = json.loads(self.run_cli("plugin", "list", "--json").stdout)
        self.assertEqual(data["claude"]["plugins"]["foo@market"]["state"], "enabled")
        self.assertEqual(data["claude"]["plugins"]["foo@market"]["version"], "1.2")
        self.assertEqual(data["codex"]["plugins"]["bar@market"]["state"], "enabled")
        self.assertEqual(data["codex"]["plugins"]["bar@market"]["version"], "2.0")

    def test_plugin_dry_run_does_not_call_native_install(self) -> None:
        (self.home / ".claude/settings.json").write_text("{}", encoding="utf-8")
        self.write_mock_cli("claude", [])
        self.run_cli("plugin", "install", "foo@market", "--agent", "claude")
        log = self.mock_log.read_text(encoding="utf-8") if self.mock_log.exists() else ""
        self.assertNotIn("plugin install", log)

    def test_plugin_apply_delegates_to_native_cli(self) -> None:
        (self.home / ".claude/settings.json").write_text("{}", encoding="utf-8")
        self.write_mock_cli("claude", [])
        self.run_cli("plugin", "install", "foo@market", "--agent", "claude", "--apply", "--json")
        log = self.mock_log.read_text(encoding="utf-8")
        self.assertIn("plugin install foo@market -s user --json", log)

    def test_unsupported_plugin_action_returns_capability_gap(self) -> None:
        proc = self.run_cli("plugin", "uninstall", "foo", "--agent", "opencode", check=False)
        self.assertEqual(proc.returncode, 2)
        self.assertIn("no native", proc.stderr)

    def test_cross_agent_duplicate_plugin_install_is_refused_without_override(self) -> None:
        (self.home / ".claude/settings.json").write_text("{}", encoding="utf-8")
        (self.home / ".codex/config.toml").write_text("", encoding="utf-8")
        self.write_mock_cli("claude", [])
        self.write_mock_cli(
            "codex",
            {"installed": [{"pluginId": "foo@market", "enabled": True}]},
        )

        refused = self.run_cli(
            "plugin", "install", "foo@other", "--agent", "claude", "--apply", check=False
        )
        self.assertEqual(refused.returncode, 2)
        log = self.mock_log.read_text(encoding="utf-8")
        self.assertNotIn("plugin install", log)

        self.run_cli(
            "plugin", "install", "foo@other", "--agent", "claude",
            "--apply", "--allow-cross-agent", "--json",
        )
        self.assertIn("plugin install foo@other", self.mock_log.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()

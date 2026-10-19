import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent


def snapshot(root):
    entries = {}
    for path in root.rglob("*"):
        if path.is_symlink():
            value = ("link", os.readlink(path))
        elif path.is_dir():
            value = ("directory",)
        else:
            value = ("file", path.read_bytes())
        entries[str(path.relative_to(root))] = value
    return entries


class SyncWorktreeTests(unittest.TestCase):
    def check_backend(self, backend):
        with tempfile.TemporaryDirectory(prefix="sync-copilot-") as temporary:
            base = Path(temporary).resolve()
            repo = base / "main checkout"
            worktree = base / "linked checkout"
            home = base / "home"
            projects = base / "projects"
            home.mkdir()
            projects.mkdir()
            (repo / "script").mkdir(parents=True)
            env = dict(os.environ, HOME=str(home), PROJECTS=str(projects),
                       GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
            for name in ("sync-copilot", "sync-copilot.ps1",
                         "configure-blackbird", "configure-blackbird.ps1"):
                shutil.copy2(ROOT / "script" / name, repo / "script" / name)
            source = repo / "copilot/skills/sample/SKILL.md"
            source.parent.mkdir(parents=True)
            source.write_text("---\nname: sample\n---\nMain checkout content.\n")
            (repo / "copilot/copilot-instructions.md").write_text(
                "# Instructions\n\n## Code Discovery\nRemove this.\n\n## Keep\nKeep this.\n"
            )

            def git(*args):
                return subprocess.run(
                    ["git", "-C", str(repo), *args], env=env,
                    capture_output=True, text=True, check=True
                )

            def sync(checkout, command):
                if backend == "bash":
                    args = ["bash", str(checkout / "script/sync-copilot"), command]
                else:
                    args = ["pwsh", "-NoProfile", "-File",
                            str(checkout / "script/sync-copilot.ps1"), command,
                            "-CopilotHome", str(home / ".copilot"),
                            "-ProjectsRoot", str(projects)]
                return subprocess.run(args, cwd=repo, env=env,
                                      capture_output=True, text=True)

            git("init", "--quiet")
            git("add", ".")
            git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                "-c", "commit.gpgsign=false", "-c", "core.hooksPath=" + os.devnull,
                "commit", "--quiet", "-m", "Fixture")
            git("worktree", "add", "--detach", str(worktree))
            (worktree / "copilot/skills/sample/SKILL.md").write_text("Worktree content.\n")

            result = sync(repo, "install")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            installed = home / ".copilot/skills/sample/SKILL.md"
            self.assertEqual(installed.resolve(), source)
            self.assertEqual(installed.read_bytes(), source.read_bytes())
            local = home / ".copilot/skills/local/SKILL.md"
            local.parent.mkdir()
            local.write_text("---\nname: local\n---\nLocal skill.\n")

            for command in ("install", "import"):
                with self.subTest(backend=backend, command=command):
                    before = snapshot(home), snapshot(worktree / "copilot")
                    result = sync(worktree, command)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertIn("linked worktree", result.stdout + result.stderr)
                    self.assertEqual((snapshot(home), snapshot(worktree / "copilot")), before)

            result = sync(worktree, "status")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            result = sync(repo, "import")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(local.resolve(), repo / "copilot/skills/local/SKILL.md")
            git("worktree", "remove", "--force", str(worktree))
            self.assertEqual(installed.read_bytes(), source.read_bytes())

    def test_bash(self):
        self.check_backend("bash")

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell is not installed")
    def test_powershell(self):
        self.check_backend("powershell")


if __name__ == "__main__":
    unittest.main()

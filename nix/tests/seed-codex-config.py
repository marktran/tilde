#!/usr/bin/env python3
"""Runs during the Nix helper build; direct runs need Python with tomlkit."""

from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest

import tomlkit


HELPER = [sys.argv.pop(1)] if len(sys.argv) > 1 else [
    sys.executable,
    str(Path(__file__).resolve().parents[1] / "home-manager/common/seed-codex-config.py"),
]
STARTER = '''model = "starter"
model_provider = "cloudflare-ai-gateway"
[model_providers.cloudflare-ai-gateway]
base_url = "https://gateway.example/openai"
env_key = "CLOUDFLARE_API_KEY"
'''
LOCAL = STARTER.replace('"starter"', '"local"') + '''
# Preserve local trust and plugin choices.
[projects."/local"]
trust_level = "trusted"
[plugins.example]
enabled = true
'''
PROFILE = 'model = "gpt-5.6-sol"\nmodel_reasoning_effort = "high"\nmodel_provider = "openai"\n'


class SeedCodexConfigTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.defaults = self.root / "defaults"
        self.defaults.mkdir()
        (self.defaults / "config.toml").write_text(STARTER)
        self.settings = self.root / ".codex"
        self.settings.mkdir()
        self.config = self.settings / "config.toml"
        self.profile = self.settings / "chatgpt.config.toml"

    def run_helper(self, success=True):
        result = subprocess.run(
            [*HELPER, str(self.defaults), str(self.settings)], capture_output=True, text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)

    def test_seed_single_config_and_preserve_existing(self):
        self.settings.rmdir()
        self.run_helper()
        self.assertEqual(self.config.read_text(), STARTER)
        self.assertFalse(self.config.is_symlink())
        self.assertEqual(stat.S_IMODE(self.config.stat().st_mode), 0o600)
        self.assertFalse(self.profile.exists())
        self.config.write_text(LOCAL)
        self.config.chmod(0o400)
        before = self.config.stat()
        self.run_helper()
        self.assertEqual(self.config.read_text(), LOCAL)
        after = self.config.stat()
        for field in ("st_mode", "st_ino", "st_mtime_ns"):
            self.assertEqual(getattr(after, field), getattr(before, field))

    def test_detach_legacy_main_links(self):
        source = self.root / "store.toml"
        source.write_text(LOCAL)
        source.chmod(0o444)
        intermediate = self.root / "intermediate"
        intermediate.symlink_to(source)
        self.config.symlink_to(intermediate)
        self.run_helper()
        self.assertFalse(self.config.is_symlink())
        self.assertEqual(self.config.read_text(), LOCAL)
        self.assertEqual(stat.S_IMODE(self.config.stat().st_mode), 0o600)
        self.assertEqual(source.read_text(), LOCAL)

    def test_profile_migration_and_idempotence(self):
        self.config.write_text(LOCAL)
        self.profile.write_text(PROFILE)
        self.run_helper()
        expected = tomlkit.parse(LOCAL)
        expected.update(model="gpt-5.6-sol", model_reasoning_effort="high")
        self.assertEqual(tomlkit.parse(self.config.read_text()), expected)
        self.assertIn("# Preserve local trust", self.config.read_text())
        self.assertFalse(self.profile.exists())
        backups = list((self.settings / "backups").iterdir())
        self.assertEqual(len(backups), 1)
        backup = backups[0]
        self.assertEqual((backup / "config.toml").read_text(), LOCAL)
        self.assertEqual((backup / "chatgpt.config.toml").read_text(), PROFILE)
        self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o700)
        # Later local choices must not be reset by another switch.
        self.config.write_text(self.config.read_text().replace('"gpt-5.6-sol"', '"later"'))
        before = self.config.read_bytes()
        self.run_helper()
        self.assertEqual(self.config.read_bytes(), before)
        self.assertEqual(list((self.settings / "backups").iterdir()), backups)

    def test_migrate_linked_profile_with_missing_main(self):
        source = self.root / "profile.toml"
        source.write_text(PROFILE)
        source.chmod(0o444)
        self.profile.symlink_to(source)
        self.run_helper()
        self.assertEqual(source.read_text(), PROFILE)
        self.assertFalse(self.profile.is_symlink())
        config = tomlkit.parse(self.config.read_text())
        self.assertEqual(config["model_provider"], "cloudflare-ai-gateway")
        self.assertEqual(config["model"], "gpt-5.6-sol")

    def test_add_missing_gateway_definition_during_migration(self):
        self.config.write_text('model_provider = "openai"\n')
        self.profile.write_text(PROFILE)
        self.run_helper()
        config = tomlkit.parse(self.config.read_text())
        self.assertEqual(config["model_provider"], "cloudflare-ai-gateway")
        self.assertEqual(config["model_providers"], tomlkit.parse(STARTER)["model_providers"])

    def test_invalid_paths_or_profile_leave_main_untouched(self):
        self.config.write_text(LOCAL)
        for bad_profile in ("broken", "directory", "invalid-toml"):
            with self.subTest(bad_profile=bad_profile):
                if bad_profile == "broken":
                    self.profile.symlink_to(self.root / "missing")
                elif bad_profile == "directory":
                    self.profile.mkdir()
                else:
                    self.profile.write_text("not valid toml [")
                self.run_helper(success=False)
                self.assertEqual(self.config.read_text(), LOCAL)
                self.assertFalse((self.settings / "backups").exists())
                if self.profile.is_dir():
                    self.profile.rmdir()
                else:
                    self.profile.unlink()
        self.config.unlink()
        self.config.symlink_to(self.root / "missing")
        self.run_helper(success=False)
        self.assertTrue(self.config.is_symlink())


if __name__ == "__main__":
    unittest.main()

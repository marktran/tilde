#!/usr/bin/env python3
"""Seed a local Codex config; migrate the retired ChatGPT profile once."""

import os
from pathlib import Path
import sys
import tempfile

import tomlkit


GATEWAY = "cloudflare-ai-gateway"


def atomic_write(path, contents):
    """Replace the file/link itself, with a private, writable regular file."""
    fd, temporary = tempfile.mkstemp(prefix=f"{path.name}.tmp.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(contents)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def read_existing(path):
    if path.exists() or path.is_symlink():
        # Never silently reset a broken link, directory, or unreadable config.
        if not path.is_file():
            raise ValueError(f"Not a regular file or readable file link: {path}")
        return path.read_bytes()
    return None


def seed_config(defaults, settings):
    target = settings / "config.toml"
    profile = settings / "chatgpt.config.toml"
    original = read_existing(target)
    profile_bytes = read_existing(profile)
    contents = original if original is not None else (defaults / "config.toml").read_bytes()

    if profile_bytes is not None:
        # Transfer only the chosen model/thinking defaults, never ChatGPT auth
        # or provider routing. TOMLKit preserves other settings and comments.
        config = tomlkit.parse(contents.decode())
        overrides = tomlkit.parse(profile_bytes.decode())
        for key in ("model", "model_reasoning_effort"):
            if key in overrides:
                config[key] = overrides[key]
        config["model_provider"] = GATEWAY
        providers = config.setdefault("model_providers", tomlkit.table())
        if GATEWAY not in providers:
            starter = tomlkit.parse((defaults / "config.toml").read_text())
            providers[GATEWAY] = starter["model_providers"][GATEWAY]
        contents = tomlkit.dumps(config).encode()
        # Retire the old repo-generated comments as well as the profile.
        contents = contents.replace(
            b"# Codex CLI user config, repo-managed as a writable out-of-store link\n"
            b"# (see nix/home-manager/common/agents.nix): codex itself rewrites this file\n"
            b"# (project trust, TUI state, notices), so runtime writes land in the checkout\n"
            b"# and show up as ordinary git drift.\n",
            b"# Codex-owned local config. Settings changes stay local, not in Git.\n",
        ).replace(
            b"# Interactive ChatGPT-auth usage: `codex --profile chatgpt` (fish abbr:\n"
            b"# codex), which layers chatgpt.config.toml on top of this file.\n",
            b"# Interactive and non-interactive Codex both use Cloudflare AI Gateway.\n",
        )

        # Snapshot resolved contents, not links into a mutable checkout or old
        # Nix generation. Keep both originals before changing either live file.
        backups = settings / "backups"
        backups.mkdir(parents=True, exist_ok=True, mode=0o700)
        backup = Path(tempfile.mkdtemp(prefix="gateway-migration-", dir=backups))
        if original is not None:
            atomic_write(backup / target.name, original)
        atomic_write(backup / profile.name, profile_bytes)
        atomic_write(target, contents)
        profile.unlink()
        print(f"Migrated Codex to Cloudflare AI Gateway; originals: {backup}")
    elif original is None or target.is_symlink():
        # Seed only if missing; detach legacy main-config links before HM's
        # orphan cleanup. Existing regular files stay completely untouched.
        settings.mkdir(parents=True, exist_ok=True)
        atomic_write(target, contents)
        print(f"Initialized app-owned Codex config: {target}")


if __name__ == "__main__":
    seed_config(Path(sys.argv[1]), Path(sys.argv[2]))

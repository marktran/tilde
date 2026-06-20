## Nix/Home Manager workflow
- This repo is managed with Nix flakes and Home Manager for `$HOME` files.
- On Linux/Omarchy, use standalone Home Manager:
  `home-manager switch --flake ~/src/mark/tilde#linux`.
- On macOS, Home Manager is folded into nix-darwin, so the standalone
  `home-manager` CLI is not installed. Apply changes with
  `sudo darwin-rebuild switch --flake ~/src/mark/tilde#mac`, which activates
  both the system and user (Home Manager) config in one step. Recent
  nix-darwin requires root for activation (`system activation must now be run
  as root`), so the `sudo` is required.
- The `homeConfigurations.mac` standalone output is kept only for
  evaluation/rollback; do not run `home-manager switch ...#mac` while
  nix-darwin owns the Home Manager profile.
- Top-level config directories still mirror target paths, but Home Manager links
  entries from them into `$HOME`; do not use GNU Stow for home-directory config.
- Many programs are configured through Home Manager modules in
  `nix/home-manager/` (e.g. `programs.ghostty.settings`), not via standalone
  dotfiles. Check there first before assuming a config is missing or editing a
  file under `$HOME`. Shared settings live in `common.nix`; platform-specific
  settings live in `darwin.nix` (macOS) and `linux.nix`.
- `system/` contains privileged Linux `/etc` files and remains outside
  standalone Home Manager.
- No platform sub-namespaces — the flake selects shared, Linux-only, and macOS-only
  modules.
- `packages.txt` (official-repo) and `aur.txt` (AUR) are package inventories, not Stow packages.
- Assume all new files and file edits should be made in this repo.
- Do not edit generated symlinks directly in `$HOME`.
- After home config changes, run the appropriate switch command for the
  platform (`home-manager switch` on Linux, `darwin-rebuild switch` on macOS).
  See `README.md` and `nix/README.md`.

## Git commits
- Never create commits with signing disabled. Do not use `--no-gpg-sign`.
- If signing fails, stop and ask me to fix signing rather than bypassing it.

## Nix/Home Manager workflow
- This repo is managed with Nix flakes and Home Manager for `$HOME` files.
- Use `home-manager switch --flake ~/src/mark/tilde#linux` on Linux/Omarchy.
- Use `home-manager switch --flake ~/src/mark/tilde#mac` on macOS.
- Top-level config directories still mirror target paths, but Home Manager links
  entries from them into `$HOME`; do not use GNU Stow for home-directory config.
- `system/` contains privileged Linux `/etc` files and remains outside
  standalone Home Manager.
- No platform sub-namespaces — the flake selects shared, Linux-only, and macOS-only
  modules.
- `packages.txt` (official-repo) and `aur.txt` (AUR) are package inventories, not Stow packages.
- Assume all new files and file edits should be made in this repo.
- Do not edit generated symlinks directly in `$HOME`.
- After home config changes, run the appropriate `home-manager switch --flake ...`
  command. See `README.md` and `nix/README.md`.

## Git commits
- Never create commits with signing disabled. Do not use `--no-gpg-sign`.
- If signing fails, stop and ask me to fix signing rather than bypassing it.

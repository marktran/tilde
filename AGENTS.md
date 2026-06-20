## Nix/Home Manager workflow
- This repo is managed with Nix flakes and Home Manager for `$HOME` files.
- Prefer the `Makefile` (run from the repo root); it auto-detects the platform
  and wraps the right commands:
  - `make` (default) / `make dry-run` — build + dry-run activation, applies
    nothing. Safe to run any time, e.g. to verify a change before applying.
  - `make switch` — build and activate this machine's config.
  - `make check` — sanity-check both hosts (build native, eval the other).
  - `make help` — list all targets.
- Under the hood `make switch` runs the platform-specific command:
  - On Linux/Omarchy, standalone Home Manager:
    `home-manager switch --flake ~/src/mark/tilde#linux`.
  - On macOS, Home Manager is folded into nix-darwin, so the standalone
    `home-manager` CLI is not installed:
    `sudo darwin-rebuild switch --flake ~/src/mark/tilde#mac`, which activates
    both the system and user (Home Manager) config in one step. Recent
    nix-darwin requires root for activation (`system activation must now be run
    as root`), so the `sudo` is required.
- The `homeConfigurations.mac` standalone output is kept only for
  evaluation/rollback; do not run `home-manager switch ...#mac` while
  nix-darwin owns the Home Manager profile.
- Repo-managed config files live under `nix/files/` and Home Manager links them
  into `$HOME`; `emacs/` is the remaining top-level live out-of-store tree. Do
  not use GNU Stow for home-directory config.
- Many programs are configured through Home Manager modules in
  `nix/home-manager/` (e.g. `programs.ghostty.settings`), not via standalone
  dotfiles. Check there first before assuming a config is missing or editing a
  file under `$HOME`. Shared settings live in `common.nix`; platform-specific
  settings live in `darwin.nix` (macOS) and `linux.nix`.
- `system/` contains privileged Linux `/etc` files and remains outside
  standalone Home Manager.
- No platform sub-namespaces — the flake selects shared, Linux-only, and macOS-only
  modules.
- `linux/packages.txt` (official-repo) and `linux/aur.txt` (AUR) are Linux-only
  package inventories, not Stow packages. Use `make pkgs` to install and
  `make pkgs-diff` to spot uncurated installed packages.
- Assume all new files and file edits should be made in this repo.
- Do not edit generated symlinks directly in `$HOME`.
- After home config changes, run `make switch` (or the platform command it
  wraps: `home-manager switch` on Linux, `sudo darwin-rebuild switch` on
  macOS). Use `make dry-run` first for risky changes. See `README.md` and
  `nix/README.md`.

## Git commits
- Never create commits with signing disabled. Do not use `--no-gpg-sign`.
- If signing fails, stop and ask me to fix signing rather than bypassing it.

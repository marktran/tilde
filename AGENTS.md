## GNU Stow workflow
- This repo is managed with GNU Stow to create symlinks into `$HOME`.
- Each top-level directory is a Stow package; its contents mirror the target tree.
- User-config packages stow into `$HOME`: `stow -t ~ <package>` (e.g. `stow -t ~ emacs`).
- `system/` is the one exception: it targets `/` (system files under `/etc`) and
  needs sudo: `sudo stow -t / system`.
- No platform sub-namespaces — install only the packages that apply to the machine
  (skip `macos` on Linux; skip `hypr`, `makima`, etc. on macOS).
- `packages.txt` is an installed-package inventory, not a Stow package.
- Assume all new files and file edits should be made in this repo.
- Do not edit files directly in `$HOME` paths that are symlinked by Stow.
- After changes, Stow is used to (re)link files into `$HOME`. See `README.md`.

## Git commits
- Never create commits with signing disabled. Do not use `--no-gpg-sign`.
- If signing fails, stop and ask me to fix signing rather than bypassing it.

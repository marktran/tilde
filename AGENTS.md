## GNU Stow workflow
- This repo is managed with GNU Stow to create symlinks into `$HOME`.
- Typical usage is `stow -t ~ <package>` (for example: `stow -t ~ emacs`).
- Assume all new files and file edits should be made in this repo.
- Do not edit files directly in `$HOME` paths that are symlinked by Stow.
- After changes, Stow is used to (re)link files into `$HOME`.

## Git commits
- Never create commits with signing disabled. Do not use `--no-gpg-sign`.
- If signing fails, stop and ask me to fix signing rather than bypassing it.

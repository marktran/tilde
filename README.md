# tilde

My dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout rule

- **Each top-level directory is a Stow package**; its contents mirror the target tree.
- **User-config packages stow into `$HOME`** (the default).
- **`system/` is the one exception — it stows into `/`** (system files under
  `/etc`) and needs `sudo`.

That's the whole rule. There are **no platform sub-namespaces**: just install the
packages that apply to a given machine (skip `macos` on Linux; skip `hypr`,
`makima`, etc. on macOS).

## Usage

```sh
# user config -> ~
stow -t ~ <package>...          # e.g. stow -t ~ nvim fish hypr

# system config -> / (Linux only)
sudo stow -t / system

# re-link after changes / remove links
stow -R -t ~ <package>          # restow
stow -D -t ~ <package>          # unstow
```

Edit files **here** and (re)stow — never edit the symlinked copies in `$HOME`
directly.

## Notes

- `packages.txt` — installed-package inventory (reference only; not a Stow package).
- Linux-only packages: `hypr`, `makima`, `voxtype`, `elephant`, `wireplumber`,
  `xcompose`, `rtorrent`. macOS-only: `macos`. Stow only what applies.
- `system/` has its own `README.md` describing its `/etc` files and which are
  live symlinks vs. reference backups.
- Submodules: `emacs/.emacs.d`, `tmux/.tmux/plugins/tpm`
  (run `git submodule update --init --recursive` on a fresh clone).

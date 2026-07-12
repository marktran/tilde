# tilde

My dotfiles, managed with [Nix](https://nixos.org/) and
[Home Manager](https://github.com/nix-community/home-manager).

See [`nix/README.md`](nix/README.md) for the Nix/Home Manager setup, concepts,
and activation steps.

## Layout

- `flake.nix` defines the Home Manager configurations.
- `nix/home-manager/common.nix` links shared home config.
- `nix/home-manager/linux.nix` links Linux/Omarchy-only home config.
- `nix/home-manager/darwin.nix` links macOS-only home config.
- `nix/files/` holds repo-managed config files that Home Manager links into
  `$HOME` (e.g. `nix/files/fish`, `nix/files/hypr`, `nix/files/mpv`,
  `nix/files/agents/skills`).
- `emacs.d/` is the Emacs config submodule, linked to `~/.emacs.d` as a live
  out-of-store tree.
- `linux/` holds Linux/Omarchy host provisioning kept outside Nix: native
  package inventories (`packages.txt`, `aur.txt`) and privileged `/etc` files
  (`etc/`, deployed by `install.sh`). See `linux/README.md`.

## Usage

A `Makefile` wraps the platform-specific workflow and auto-detects the host.
Run targets from the repo root:

```sh
make            # list targets
make switch     # build + activate this machine's config
make dry-run    # build + dry-run activation (applies nothing)
make check      # sanity-check both hosts
make update     # update flake inputs (flake.lock)
make rollback   # roll back to the previous generation
```

Underneath, `make switch` runs the right command per platform:

```sh
# Linux / Omarchy (standalone Home Manager)
home-manager switch --flake ~/src/mark/tilde#linux

# macOS (nix-darwin; activates system + Home Manager, needs root)
sudo darwin-rebuild switch --flake ~/src/mark/tilde#mac
```

Do not run `home-manager switch ...#mac` while nix-darwin owns the Home Manager
profile. Edit files here, then switch. Do not edit generated symlinks in
`$HOME` directly.

Home Manager owns the home-directory links. Do not use `stow` for `$HOME`.

## Gmail and Notmuch

See [`docs/EMACS.md`](docs/EMACS.md) for the Linux Gmail, Lieer, Notmuch, and
Emacs setup.

## Notes

- `linux/packages.txt` — official-repo package inventory (install with
  `make pkgs`, or `sudo pacman -S --needed - < linux/packages.txt`).
- `linux/aur.txt` — AUR package inventory (install with `make pkgs`, or
  `paru -S --needed - < linux/aur.txt`).
- `make pkgs-diff` lists explicitly-installed packages not yet curated into
  those files.
- Privileged Linux `/etc` files live in `linux/etc/` and are deployed with
  `make system` (wraps `sudo linux/install.sh`); `make system-diff` shows
  drift. See `linux/README.md`. These remain outside Home Manager.
- Submodule: `emacs.d` (the Emacs config repo, linked to `~/.emacs.d`).
  Run `git submodule update --init --recursive` on a fresh clone.

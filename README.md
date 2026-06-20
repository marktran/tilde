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
- `emacs/` still mirrors its target path as a live out-of-store tree.
- `system/` contains privileged Linux `/etc` files and is not managed by Home
  Manager.

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

## Notes

- `packages.txt` — official-repo package inventory (install with `pacman -S --needed - < packages.txt`; not a Stow package).
- `aur.txt` — AUR package inventory (install with `paru -S --needed - < aur.txt`; not a Stow package).
- `system/` has its own `README.md` describing its `/etc` files. These are
  privileged Linux system files and remain outside standalone Home Manager.
- Submodules: `emacs/.emacs.d`, `tmux/.tmux/plugins/tpm`
  (run `git submodule update --init --recursive` on a fresh clone).

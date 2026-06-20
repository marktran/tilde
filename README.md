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
- Existing top-level directories such as `fish/`, `emacs/`, `hypr/`, and
  `agents/` still mirror their target paths. Home Manager links entries from
  those directories into `$HOME`.
- `system/` contains privileged Linux `/etc` files and is not managed by Home
  Manager.

## Usage

Linux / Omarchy:

```sh
home-manager switch --flake ~/src/mark/tilde#linux
```

macOS:

```sh
home-manager switch --flake ~/src/mark/tilde#mac
```

Edit files here, then switch with Home Manager. Do not edit generated symlinks
in `$HOME` directly.

Home Manager owns the home-directory links. Do not use `stow` for `$HOME`.

## Notes

- `packages.txt` — official-repo package inventory (install with `pacman -S --needed - < packages.txt`; not a Stow package).
- `aur.txt` — AUR package inventory (install with `paru -S --needed - < aur.txt`; not a Stow package).
- `system/` has its own `README.md` describing its `/etc` files. These are
  privileged Linux system files and remain outside standalone Home Manager.
- Submodules: `emacs/.emacs.d`, `tmux/.tmux/plugins/tpm`
  (run `git submodule update --init --recursive` on a fresh clone).

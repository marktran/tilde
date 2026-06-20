# Nix and Home Manager Migration

This is the first migration layer from GNU Stow to Nix + Home Manager.

The current repo is still arranged as Stow packages. The Home Manager modules in
this directory deliberately preserve that shape by linking entries from the
checkout at `~/src/mark/tilde`.

## Concepts

- Nix installs packages and build outputs into `/nix/store`. Store paths are
  immutable, so they are safe to share between generations.
- Nixpkgs is the large package collection Nix usually evaluates from.
- A flake is a pinned entry point. `flake.nix` declares inputs and outputs;
  `flake.lock` records the exact revisions used.
- Home Manager is a Nix module system for your user environment: files under
  `$HOME`, user packages, shell setup, and user services.
- A generation is one activated version of your Home Manager profile. Switching
  creates a new generation; rollback selects an older one.
- NixOS manages Linux system configuration. Home Manager does not manage `/etc`
  on Omarchy/Arch.
- nix-darwin is the macOS equivalent for system-level macOS settings. It is
  optional and separate from the standalone Home Manager setup here.

## Why This Uses Out-of-Store Symlinks

Most examples copy files into the Nix store and link from there. That is more
reproducible, but the store is read-only. This repo has mutable config
directories such as `.emacs.d`, `.config/fish`, and `.tmux`, so the first pass
uses Home Manager's out-of-store symlinks. That keeps behavior close to Stow:

```text
~/.config/fish -> ~/src/mark/tilde/fish/.config/fish
~/.claude/settings.json -> ~/src/mark/tilde/claude/.claude/settings.json
```

Individual configs can move from file links to typed Home Manager options, for
example `programs.git`, `programs.fish`, or `programs.tmux`. Git is the first
typed migration: Home Manager now generates `~/.config/git/config` through
`programs.git`, plus `~/.config/git/allowed_signers` and
`~/.config/git/ignore`.

This bridge intentionally follows the current live Stow granularity. Some
targets are whole-directory links, while stateful directories such as
`~/.claude`, `~/.pi/agent`, `~/.config/hypr`, and `~/.config/mpv` keep their real
parent directories and only link selected children.

## Hosts

The flake exposes two standalone Home Manager configurations:

```sh
home-manager switch --flake ~/src/mark/tilde#linux
home-manager switch --flake ~/src/mark/tilde#mac
```

The Linux host imports shared config plus Linux-only config. Some of this is
still linked from the checkout (`hypr`, `makima`, `rtorrent`, `typora`, `mpv`),
while other pieces are now typed or store-backed:

- `programs.ghostty` Linux-only settings (keybinds, `gtk-toolbar-style`,
  `async-backend`).
- `systemd.user.services.voxtype` (typed user service; binary stays
  system-installed).
- Store-backed static files: `.XCompose`, `voxtype/config.toml`,
  `elephant/websearch.toml`, `elephant/google-favicon.png`, the WirePlumber
  Shure MV7 override, and `mpv/mpv.conf` + `mpv/input.conf` (mpv `scripts/`,
  `bin/`, `script-opts/` stay linked).

Shared store-backed static files (both hosts): `tmux/.tmux.conf` (the `.tmux`
directory stays linked because TPM writes plugins into it).

The macOS host imports shared config plus `macos`.

## Quick Check

Before switching, sanity-check the flake with the repo-local script:

```sh
nix/check.sh        # both hosts (default)
nix/check.sh linux  # only linux
nix/check.sh mac    # only mac
```

It builds the activation package for the *native* host and evaluates the other
host (eval-only, so it catches evaluation/type errors without needing a
cross-platform builder), then prints `home.stateVersion` for each.

## Step 1: Install Nix On Omarchy

Omarchy is Arch-based, so prefer Arch's official `nix` package first. This keeps
the install managed by `pacman` and uses Arch's systemd units and profile
scripts.

```sh
sudo pacman -S nix
sudo systemctl enable --now nix-daemon.socket
```

Open a new shell and verify:

```sh
nix --version
nix --extra-experimental-features 'nix-command flakes' run nixpkgs#hello
```

If flake commands are not enabled yet, create `~/.config/nix/nix.conf` with:

```conf
experimental-features = nix-command flakes
```

Then open another new shell.

The older `nix-shell -p hello --run hello` command uses channels and expects
`<nixpkgs>` in `NIX_PATH`. The Arch package does not create that channel by
default, and this repo uses flakes instead.

If the Arch package ever causes trouble, the upstream Nix project also provides
a multi-user installer:

```sh
bash -lc 'curl -L https://nixos.org/nix/install | sh -s -- --daemon'
```

## Step 2: Let Nix See the New Flake Files

Flakes only include files Git knows about. Before testing this scaffold, stage
the Nix files:

```sh
git add flake.nix nix
```

You do not need to commit before testing.

Then create the initial lock file:

```sh
nix flake lock
git add flake.lock
```

`flake.lock` is the file that pins the exact `nixpkgs` and Home Manager
revisions.

## Step 3: Build Without Activating

On the ThinkPad:

```sh
cd ~/src/mark/tilde
nix run github:nix-community/home-manager -- build --flake .#linux
```

On the Mac:

```sh
cd ~/src/mark/tilde
nix run github:nix-community/home-manager -- build --flake .#mac
```

This creates a `result` symlink but does not change your live home directory.

## Step 4: Dry Run Activation

After the build succeeds, run the generated activation script in dry-run mode.
This checks collisions and prints the activation steps without replacing your
current Stow symlinks.

ThinkPad:

```sh
DRY_RUN=1 VERBOSE=1 ./result/activate
```

If the dry run is clean, activate Home Manager:

```sh
./result/activate
```

The bridge entries use `force = true` because Stow already owns these paths as
symlinks. Home Manager will replace Stow's symlinks with Home Manager symlinks
that still resolve back to this checkout.

Do not unstow `system` as part of Home Manager migration.

## Step 5: Verify Ownership

After the first successful switch, the config enables the `home-manager`
command. Verify the active generation:

```sh
home-manager generations
```

Then verify the important live links still point into this checkout:

```sh
find ~ -maxdepth 4 -type l -printf '%p -> %l\n' | rg 'src/mark/tilde|home-manager'
```

Future Linux switches can use:

```sh
home-manager switch --flake ~/src/mark/tilde#linux
```

Do not run `stow -D` after Home Manager owns the links; Stow can remove links
that Home Manager just created because both point to the same checkout files.
At that point "no Stow" means stop using Stow for `$HOME` and let Home Manager
own future changes.

## Step 6: Roll Back If Needed

```sh
home-manager generations
home-manager switch --rollback
```

## System-Level Linux Files

The `system/` package targets `/etc` and remains outside Home Manager on
Omarchy/Arch:

```sh
sudo stow -t / system
```

Those files can eventually move into NixOS modules if the ThinkPad moves to
NixOS. Until then, keep them explicit and privileged.

## Migration Order After the Bridge Works

1. Keep out-of-store links for large mutable app directories.
2. Move simple static files to store-backed `home.file` links when you want more
   reproducibility.
3. Move app configs to typed Home Manager modules only when the module improves
   clarity.
4. Add package management gradually through `home.packages`.
5. Add nix-darwin later for macOS system settings and Homebrew orchestration.

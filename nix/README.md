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
directories such as `.emacs.d` and app extension trees, so the first pass uses
Home Manager's out-of-store symlinks. That keeps behavior close to Stow:

```text
~/.pi/agent/extensions -> ~/src/mark/tilde/nix/files/pi/agent/extensions
~/.config/nvim/lazy-lock.json -> ~/src/mark/tilde/nix/files/nvim/lazy-lock.json
```

Individual configs can move from file links to typed Home Manager options, for
example `programs.git`, `programs.fish`, or `programs.tmux`. Git, Fish,
Ghostty, tmux, direnv, and zoxide now use typed Home Manager config where it is
clearer than file links.

This bridge intentionally follows the current live Stow granularity. Some
targets are whole-directory links, while stateful directories such as
`~/.pi/agent`, `~/.config/hypr`, and `~/.config/mpv` keep their real parent
directories and only link selected children. Claude settings and commands are
store-backed because they are static; app-generated Claude state stays outside
this repo.

## Hosts

The daily workflow differs by platform:

- **Linux** uses standalone Home Manager:

  ```sh
  home-manager switch --flake ~/src/mark/tilde#linux
  ```

- **macOS** uses nix-darwin, which folds Home Manager in, so one command
  activates both the system (Homebrew, etc.) and the user environment:

  ```sh
  darwin-rebuild switch --flake ~/src/mark/tilde#mac
  ```

Host-specific aliases are also provided and are identical to the primaries, so
each machine can be referenced by name (`#x1-carbon` == `#linux`,
`#macbook-air` == `#mac`).

The `homeConfigurations.mac` / `#macbook-air` standalone entries are kept for
flake evaluation and as a rollback path. Do not run them with
`home-manager switch` while nix-darwin owns the Home Manager profile.

The Linux host imports shared config plus Linux-only config. Static files and
helper scripts are typed or store-backed; only mutable lock/state files and
plugin-like trees stay linked from the checkout:

- `programs.ghostty` Linux-only settings (keybinds, `gtk-toolbar-style`,
  `async-backend`).
- `systemd.user.services.voxtype` (typed user service; binary stays
  system-installed).
- Store-backed static files: `.XCompose`, `voxtype/config.toml`,
  `elephant/websearch.toml`, `elephant/google-favicon.png`, the WirePlumber
  Shure MV7 override, Typora user config, `rtorrent.rc`, Makima TOMLs,
  `mpv/mpv.conf`, `mpv/input.conf`, mpv `script-opts/*.conf`, mpv helper
  scripts, and Hypr/Omarchy `hypr/*.conf` + helper scripts.

Shared typed config (both hosts) includes `programs.tmux`: Home Manager
generates `~/.config/tmux/tmux.conf`, tmux itself stays native/Homebrew-owned,
and tmux plugins come from Nix `pkgs.tmuxPlugins` rather than TPM checkouts.
Home Manager also owns shared portable CLI tools (`sesh`, `tree`, `pwgen`,
`calc`, `fzf`, `fd`, `ripgrep`, `jq`), spellcheck command packages, Neovim, and
mise with the Nix profile pinned last in PATH, plus shared store-backed
helpers/config such as `~/bin`, Fish completions, Claude settings/commands, Pi
static config, and Neovim Lua config.

The macOS host is a nix-darwin system (`nix/darwin/configuration.nix`) with
Home Manager folded in. nix-darwin declares the Homebrew brews/casks/taps
(replacing the old linked `macos/Brewfile`) and is fully declarative:
`homebrew.onActivation.cleanup = "uninstall"` removes any package or tap that is
installed but not declared (dependencies of declared packages are kept). Other
defaults: `nix.enable = false` (the upstream installer keeps managing the
nix-daemon and `/etc/nix/nix.conf`), and fish stays Homebrew-managed as the
login shell.

Homebrew's tap-trust is machine-local state nix-darwin cannot manage. Because
`cleanup = "uninstall"` makes `brew bundle --cleanup` load every declared
formula, the declared third-party taps must be trusted once per machine or the
switch fails:

```sh
brew trust d12frosted/emacs-plus dopplerhq/cli oven-sh/bun
```

To preview what a switch would uninstall before activating:

```sh
nix eval --raw ~/src/mark/tilde#darwinConfigurations.mac.config.homebrew.brewfile > /tmp/Brewfile
brew bundle cleanup --file=/tmp/Brewfile   # no --force = dry run
```

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

Early bridge entries used `force = true` because Stow already owned those paths
as symlinks. The generic Stow bridge helper is now gone: remaining live-editable
paths are explicit Home Manager `home.file` entries using out-of-store symlinks,
and static files are store-backed.

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
own future changes. The only remaining Stow workflow is the privileged
`system/` package for Linux `/etc` files.

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

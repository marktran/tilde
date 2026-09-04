# Nix and Home Manager

Home Manager modules and repo-managed files for `$HOME` on both hosts.
Live-editable trees are linked from the checkout at `~/src/mark/tilde`;
other managed files are store-backed or typed Home Manager config. App-owned
configs such as Codex's are seeded as writable local files instead.

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
directories such as `.emacs.d` and app extension trees, so those use Home
Manager's out-of-store symlinks:

```text
~/.pi/agent/extensions -> ~/src/mark/tilde/nix/files/pi/agent/extensions
~/.config/nvim/lazy-lock.json -> ~/src/mark/tilde/nix/files/nvim/lazy-lock.json
```

Individual configs can move from file links to typed Home Manager options, for
example `programs.git`, `programs.fish`, or `programs.tmux`. Git, Fish,
Ghostty, tmux, direnv, and zoxide now use typed Home Manager config where it is
clearer than file links.

Link granularity is deliberate. Some targets are whole-directory links, while
stateful directories such as `~/.pi/agent`, `~/.config/hypr`, and
`~/.config/mpv` keep their real parent directories and only link selected
children. Claude settings are store-backed because they are static;
app-generated Claude state stays outside this repo.

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

- **museum** (`#museum`) is the headless exe.dev VM for Museum development
  (user `exedev`, `/home/exedev`). It imports only
  `nix/home-manager/core.nix` — the fish/git/neovim/Herdr/Pi core that
  `common.nix` layers workstation extras on top of — plus
  `nix/hosts/museum/home.nix` (signing off; no 1Password there). It is
  provisioned and updated remotely by `script/exe-setup.sh` in the museum
  repo, which clones this repo to `~/src/mark/tilde` (the out-of-store links
  require that exact path) and activates the flake output; never activate it
  from a laptop. `nix/check.sh` builds it natively on Linux.

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
- Store-backed static files: `.XCompose`, `voxtype/config.toml`, the
  WirePlumber Shure MV7 override, Typora user config, `rtorrent.rc`, Makima
  TOMLs, `mpv/mpv.conf`, `mpv/input.conf`, mpv `script-opts/*.conf`, mpv helper
  scripts, and the Hypr/Omarchy `hypr/` config + helper scripts.

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
formula and cask, the declared third-party packages must be trusted once per
machine or the switch fails:

```sh
brew trust --formula \
  d12frosted/emacs-plus/emacs-plus@30 depot/tap/depot oven-sh/bun/bun
brew trust --cask dopplerhq/doppler/doppler
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
This checks collisions and prints the activation steps without changing the
live home directory.

ThinkPad:

```sh
DRY_RUN=1 VERBOSE=1 ./result/activate
```

If the dry run is clean, activate Home Manager:

```sh
./result/activate
```

Live-editable paths are explicit Home Manager `home.file` entries using
out-of-store symlinks; static files are store-backed. `force = true` entries
overwrite pre-existing files at those paths instead of aborting activation.

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

## Step 6: Roll Back If Needed

```sh
home-manager generations
home-manager switch --rollback
```

## System-Level Linux Files

Linux `/etc` files live in `linux/etc/` and remain outside Home Manager on
Omarchy/Arch. Deploy them with the install script:

```sh
sudo linux/install.sh      # deploy (or: make system)
linux/install.sh --check   # dry run / show drift (or: make system-diff)
```

Early-boot and security files are installed as real copies; runtime acpid
events are symlinked; `etc/pam.d/sudo` is a reviewed manual step. See
`linux/README.md`.

Those files can eventually move into NixOS modules if the ThinkPad moves to
NixOS. Until then, keep them explicit and privileged.

## Design Notes

Durable decisions worth keeping in mind when changing this config.

### Global agent preferences

`nix/files/agents/preferences.md` is shared personal guidance for Pi, Codex,
and Claude Code. It prefers Ruby over Python for new standalone scripts and
tests while respecting existing project languages and simple shell glue.
Home Manager includes it in `~/.pi/agent/AGENTS.md`, `~/.codex/AGENTS.md`, and
`~/.claude/CLAUDE.md`. Pi's existing workflow-proportionality rules remain
Pi-specific. Restart agent sessions to load updated instructions.

Existing unmanaged Codex/Claude instruction files are not forcibly replaced;
merge their contents into the managed instructions before switching that host.

### Codex: one gateway config, local preferences

`nix/files/codex/config.toml` is the only starter config. Home Manager copies it
to `~/.codex/config.toml` only if missing. The live config is an ordinary
writable file owned by Codex, not a link into the store or this checkout.
Model/thinking choices, project trust, notices, and other runtime settings
stay local and do not create Git changes.

Interactive and non-interactive Codex both use Cloudflare AI Gateway. Fish
exports `CLOUDFLARE_API_KEY` from the existing gateway credentials and does not
select a ChatGPT profile. New shells clear the retired `codex` abbreviation;
run `abbr --erase codex` in an already-open Fish shell, then restart Codex.
Other launch environments must also supply `CLOUDFLARE_API_KEY`.

Activation retires an existing `chatgpt.config.toml` once: it copies both
original configs to a private `~/.codex/backups/gateway-migration-*/` directory,
transfers the profile's model/thinking choices into the main config, selects
the gateway provider, and removes the active profile file. Other base settings
are preserved. Model availability still depends on the gateway's upstream API.
Once migrated, subsequent switches leave existing regular configs untouched.
ChatGPT credentials are not deleted; they no longer select the model provider.

The starter omits machine-specific trust and generated notices. Edit it to
change defaults for future setups; existing machines need those changes
applied separately to their local config. Legacy main-config symlinks are
copied to private writable files **before** Home Manager's orphan cleanup.
Broken links fail activation instead of silently resetting settings. Old
generations may reinstate links on rollback, so back up local configs before
rolling back across this migration.

The helper is Ruby, using `toml-cli` for comment-preserving TOML edits.
Minitest regression tests run during the native helper build (`make check`).
They can also run directly with Ruby, Minitest, and `toml-cli` installed:

```sh
ruby nix/tests/seed-codex-config.rb
```

### Pi settings and package updates

`nix/files/pi/agent/settings.default.json` is the declarative source for Pi
settings, but `~/.pi/agent/settings.json` remains writable so Pi can persist
runtime-only state. Home Manager overlays the tracked defaults onto the live
file during activation, replacing tracked arrays such as `packages` while
preserving keys that exist only in the live file.

Pi's native startup check reports when an unpinned npm or git package has a
newer version. Package updates stay explicit: run `pi update --extensions` when
Pi displays the notification.

### PATH ordering: Nix profile pinned last

Native PATH ordering is asymmetric:

- **Linux:** `~/.nix-profile/bin` is already last, so Nix tools cannot shadow
  `/usr/bin` (pacman) or Homebrew.
- **macOS:** `~/.nix-profile/bin` comes *before* `/opt/homebrew/bin`, so Nix
  tools would shadow Homebrew.

To make this consistent and safe, Fish pins `~/.nix-profile/bin` at the
**lowest** PATH priority on both machines, in `programs.fish.shellInitLast`
(after typed shell integrations like mise, which rewrite PATH). The Home
Manager profile (which also contains `fish`, `man`, etc.) therefore never
shadows system tools, and `home.packages` is purely additive -- it only
provides tools the OS lacks (e.g. `direnv`). Overriding a system tool later is
then an explicit, separate decision.

The `Makefile` separately appends the Nix profile locations to PATH so `nix` /
`home-manager` / `darwin-rebuild` are found in its non-interactive recipe
shell (also appended, never shadowing system tools).

### macOS Homebrew quirks

- **Trust is machine-local** and not managed by nix-darwin
  (`~/.homebrew/trust.json`). With `homebrew.onActivation.cleanup =
  "uninstall"`, the declared third-party formulae and casks must be trusted
  once per machine or `darwin-rebuild switch` fails/warns:
  `brew trust --formula d12frosted/emacs-plus/emacs-plus@30 depot/tap/depot
  oven-sh/bun/bun` and
  `brew trust --cask dopplerhq/doppler/doppler`.
- **Renamed formulae + outdated kegs can make cleanup uninstall needed
  dependencies.** nix-darwin runs `brew bundle --no-upgrade --force-cleanup`;
  brew bundle skips outdated formulae when computing which dependencies to
  keep ("Skipping X: most recent version not installed"). When a transitive
  dependency is also renamed upstream (e.g. `sdl2` -> `sdl2-compat`, needed
  by mpv/ffmpeg), it falls out of the keep-set and gets uninstalled on every
  switch. Fix by upgrading the affected chain, e.g.
  `brew upgrade sdl2 ffmpeg mpv`, so dependency resolution works again.
  Running `brew upgrade` occasionally prevents recurrence.

### macOS Touch ID for sudo

`security.pam.services.sudo_local.touchIdAuth = true` plus `reattach = true`
(pam_reattach) so the prompt also works inside tmux/screen. `/etc/pam.d/sudo`
already includes `sudo_local`.

### Open follow-ups

- [ ] macOS: confirm `programs.tmux` after a `darwin-rebuild switch` (Linux is
  verified; the Mac just needs a tmux launch).

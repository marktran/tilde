# Nix/Home Manager Migration Plan

This is the working plan for finishing the migration from GNU Stow to Nix +
Home Manager across:

- `linux`: ThinkPad X1 Carbon Gen 13, Omarchy Linux
- `mac`: MacBook Air, macOS

## Current State

- Nix is installed on both machines.
- Flakes are enabled on both machines.
- Linux uses standalone Home Manager.
- macOS uses nix-darwin with Home Manager folded in (one `darwin-rebuild
  switch` activates system + user env). Homebrew brews/casks/taps are declared
  in `nix/darwin/configuration.nix` and are fully declarative
  (`homebrew.onActivation.cleanup = "uninstall"`): undeclared packages/taps are
  removed on switch. `nix.enable = false` and fish stays Homebrew-managed as the
  login shell.
- Homebrew tap-trust is machine-local state nix-darwin cannot manage. With
  `cleanup = "uninstall"`, the declared third-party taps must be trusted once
  per machine or the switch fails:
  `brew trust d12frosted/emacs-plus dopplerhq/cli oven-sh/bun`.
- A standalone macOS Home Manager config (`#mac` / `#macbook-air`) is kept for
  evaluation and rollback only; do not `home-manager switch` it while
  nix-darwin owns the profile.
- Home Manager owns `$HOME` config links; Stow is no longer part of the normal
  home-directory workflow.
- `system/` is still the Linux `/etc` exception and remains outside standalone
  Home Manager.
- `programs.git` is migrated to typed Home Manager config.
- Git config is generated at `~/.config/git/config`.
- Git ignore rules are generated at `~/.config/git/ignore`.
- Git SSH signing allow-list is generated at `~/.config/git/allowed_signers`.
- The GitHub credential helper is platform-specific:
  - Linux: `/usr/bin/gh auth git-credential`
  - macOS: `/opt/homebrew/bin/gh auth git-credential`

## Daily Workflow

Use the machine-specific config. Linux is standalone Home Manager; macOS is
nix-darwin:

```sh
home-manager switch --flake ~/src/mark/tilde#linux
darwin-rebuild switch --flake ~/src/mark/tilde#mac
```

Run `home-manager switch` after changing this repo, pulling changes from another
machine, or updating `flake.lock`. Do not run it just because a new shell was
opened.

For risky changes, build and dry-run first:

```sh
cd ~/src/mark/tilde
nix build .#homeConfigurations.linux.activationPackage
DRY_RUN=1 VERBOSE=1 ./result/activate
```

```sh
cd ~/src/mark/tilde
nix build .#homeConfigurations.mac.activationPackage
DRY_RUN=1 VERBOSE=1 ./result/activate
```

If the dry run is clean, activate:

```sh
./result/activate
```

## Safety Rules

- Do not use `stow` for `$HOME` config anymore.
- Do not run `stow -D` against old home packages after Home Manager owns the
  links; it can remove links Home Manager created because they resolve back to
  the same checkout.
- Keep macOS conservative by default. Only set `force = true` for macOS paths
  after auditing or intentionally deleting the conflicting file.
- Linux bridge links currently use `force = true` because the original Stow
  symlinks were audited on the ThinkPad.
- Keep privileged Linux `/etc` files explicit. `system/` is not managed by
  standalone Home Manager.
- Commit logical steps before moving to the next migration stage.

## Remaining Work

### 1. Verify Both Machines After Git Migration

- [x] On Linux, confirm Git uses Home Manager generated config:

  ```sh
  git config --show-origin --get user.email
  git config --show-origin --get-regexp '^credential\.https://github\.com\.helper$'
  git config --show-origin --get user.signingkey
  ```

- [x] On macOS, confirm Git uses the Homebrew `gh` helper:

  ```sh
  git config --show-origin --get-regexp '^credential\.https://github\.com\.helper$'
  ```

- [x] Confirm old home-level Git files are gone or intentionally unmanaged:

  ```sh
  test ! -e ~/.gitconfig
  test ! -e ~/.gitignore
  ```

  - [x] Linux confirmed.
  - [x] macOS confirmed.

### 2. Clean Up The Stow Bridge As Configs Move

- [x] Remove now-empty Git package directories from the repo if they are empty
  on disk.
- [ ] Periodically inspect remaining bridge-managed files:

  ```sh
  rg -n 'home.file = stow.linksFor|\{\s*name = ' nix/home-manager
  ```

- [ ] For each migrated package, remove its entries from `stow.linksFor`.
- [ ] Prefer typed Home Manager modules when they make the config clearer.
- [ ] Keep file links for large mutable app configs where typed modules would
  add noise.

### 3. Candidate Typed Module Migrations

Prefer small, shared, low-risk modules first.

- [x] Fish:
  - [x] Split the bridge from one whole `.config/fish` directory link to
    explicit Fish file/directory links.
  - [x] Move `config.fish` plus simple aliases/abbreviations to
    `programs.fish`.
  - [x] Move pure static functions (`fish_prompt`, `fish_greeting`, `cd`,
    `ls`, `l.`, `btmm`) to `programs.fish.functions`.
  - [x] Store-back remaining helper/plugin files (`bass`, `fisher`) plus
    completions; keep `fish_variables` and `local.fish` as local mutable bridge
    links rather than typed/generated config.
  - [x] Keep machine-specific PATH or environment details explicit (PATH,
    Omarchy, Homebrew/CPATH, Obsidian, grok now expressed in
    `programs.fish.shellInit`).
  - [x] Inline `exports.fish` and `colors.fish` into `programs.fish` and drop
    those linked files.
  - [x] Avoid breaking interactive startup; test by opening a new shell after
    activation.
    - [x] Linux activation tested.
    - [x] macOS activation tested.

- [x] Tmux:
  - [x] Migrated shared config to typed `programs.tmux` in `common.nix`
    (`package = null`, so native/Homebrew tmux still owns the binary).
  - [x] Replaced TPM-managed plugins with Nix-provided
    `pkgs.tmuxPlugins.{sensible,yank,vim-tmux-navigator}`.
  - [x] Removed the old `.tmux.conf` store-backed link, `.tmux` bridge link,
    and TPM submodule.
  - [x] Linux activation tested (`home-manager switch --flake ...#linux`; old
    `~/.tmux.conf`/`~/.tmux` links removed, XDG tmux config parses).
  - [ ] macOS activation tested.

- [x] Shell environment:
  - [x] Move portable static editor/pager/color/zoxide variables to
    `home.sessionVariables`.
  - [x] Keep PATH and OS-specific startup logic in Fish, but generated from
    `programs.fish` rather than a linked file.
  - [x] Move direnv and zoxide Fish hooks to typed modules
    (`programs.direnv`, `programs.zoxide` with `--cmd j`).
  - [x] Keep mise/orbstack startup in `programs.fish.shellInit`.
  - [x] Linux activation tested.
  - [x] macOS activation tested.

- [ ] Simple one-file configs:
  - Convert files only when generated Nix is easier to read than the original.
  - Good candidates are small static config files with no app-managed state.
  - [x] Ghostty migrated to typed `programs.ghostty` (`package = null`, systemd
    and shell integration disabled); linked `ghostty/config` removed.
    - [x] Shared settings in `common.nix`; Linux/Hyprland-only settings
      (`gtk-toolbar-style`, `async-backend = epoll`, keybinds) in `linux.nix`
      so they no longer land on macOS.
    - [x] Linux activation tested (`ghostty +validate-config` passes).
    - [x] macOS activation tested (`ghostty +validate-config` passes).
  - [x] `.hunspell_default` moved from the Emacs bridge to a shared
    store-backed Home Manager file.
  - [x] Linux-only static one-file configs store-backed in `linux.nix`: Typora
    user config, `rtorrent.rc`, Makima TOMLs, mpv script options, and
    Hypr/Omarchy `hypr/*.conf` files.
  - [x] Store-backed remaining low-risk static/helper trees: `~/bin` scripts,
    Fish completions/helpers, Pi static config (`agents`, `themes`, `prompts`,
    keybindings/models/presets), Neovim Lua config (but not `lazy-lock.json`),
    Hypr helper scripts, and mpv `bin/` + `scripts/`.
  - [x] Removed stale repo-only legacy configs that were no longer linked or
    active: old `.bash_profile`, Python/Ruby dotfiles, and the obsolete
    Obsidian custom-window-title plugin source.

### 4. Package Management Strategy

Do not blindly move every package into Nix.

PATH ordering is asymmetric, so this matters when choosing what Nix should own:

- Linux: `~/.nix-profile/bin` is **last** in PATH, so Nix tools cannot shadow
  `/usr/bin` (pacman) or Homebrew.
- macOS: `~/.nix-profile/bin` is **before** `/opt/homebrew/bin`, so Nix tools
  **do** shadow Homebrew there.

Decision: pin `~/.nix-profile/bin` at the **lowest** PATH priority on both
machines (asserted in fish after `mise activate`, since mise rewrites PATH).
This is consistent and safe: the Home Manager profile (which also contains
`fish`, `man`, etc.) never shadows system tools, and `home.packages` is purely
additive -- it only provides tools the OS does not (e.g. `direnv`). To override
a system tool later, that becomes an explicit, separate decision.

- [x] Settle PATH ordering: Nix profile pinned last; survives mise prompt
  hooks and directory changes.
  - [x] Linux activation tested (`~/.nix-profile/bin` is last; `fish`/`man`
    resolve from the system; `direnv` still resolves from Nix).
  - [x] macOS activation tested. Notably this fixed a real bug: `fish`
    previously resolved from `~/.nix-profile/bin/fish`; it now resolves from
    Homebrew, with the Nix profile near the end of PATH.

- [x] Decide which CLI tools should be installed by Home Manager modules.
  - [x] `direnv` is owned by `programs.direnv` (referenced by fish startup; was
    missing on Linux, so purely additive there).
  - [x] `zoxide` Fish integration is owned by `programs.zoxide` with
    `--cmd j`; the Nix profile stays last so interactive command lookup still
    prefers native packages when present.
  - [x] Portable CLI tools in `home.packages`: `sesh`, `tree`, `pwgen`,
    `calc`, `fzf`, `fd`, `ripgrep`, and `jq`. Removed now-Nix-owned entries
    from native inventories where this repo declared them (`packages.txt`,
    `aur.txt`, nix-darwin Homebrew brews).
- [x] Keep OS integration packages in the native package manager when that is
  more practical:
  - Linux system/desktop packages can remain in `packages.txt` and `aur.txt`
    until there is a clear reason to move them.
  - macOS GUI/Homebrew-managed apps are now declared via nix-darwin's
    `homebrew` module in `nix/darwin/configuration.nix` (brews/casks/taps).
    Homebrew still installs them; nix-darwin just makes the list declarative.
- [x] Start with portable CLI tools that are the same on Linux and macOS.
- [x] Avoid changing the owner of critical tools like `git`, `gh`, shells, or
  desktop services until the tradeoff is explicit.
  - [x] Linux activation tested (`direnv` resolves from `~/.nix-profile/bin`,
    fish hook active).
  - [x] macOS activation tested (`direnv` was absent before, now Nix-owned at
    `~/.nix-profile/bin`; no shadowing, fish hook active).

### 5. Linux-Only Work

- [x] Keep Omarchy/Hyprland config under `linux.nix`.
  - [x] Static `hypr/*.conf` files and helper scripts are store-backed via
    `xdg.configFile`.
- [ ] Keep Linux-only apps out of common config:
  - Typora
  - mpv
  - Hyprland
  - Makima
  - Voxtype
  - WirePlumber
  - rtorrent
- [x] Decide whether `voxtype.service` should become a typed
  `systemd.user.services` definition instead of a linked unit file.
  - [x] Migrated to typed `systemd.user.services.voxtype` in `linux.nix`;
    binary stays system-installed (`/usr/lib/voxtype`). Linked unit file
    removed.
  - [x] Linux activation tested (service enabled, active, restarts cleanly).
- [ ] Document the remaining `system/` workflow for `/etc` clearly:

  ```sh
  sudo stow -t / system
  ```

- [ ] Longer-term option: move Linux system config to NixOS only if the laptop
  moves from Omarchy/Arch to NixOS.

### 6. macOS-Only Work

- [x] Introduce nix-darwin (`nix/darwin/configuration.nix`), with Home Manager
  folded in via `home-manager.darwinModules.home-manager`.
  - [x] Homebrew orchestration: brews/casks/taps declared from the real
    installed inventory; old linked `macos/Brewfile` removed.
  - [x] macOS activation tested (`darwin-rebuild switch --flake .#mac`):
    `brew bundle` is a no-op, direnv resolves from `~/.nix-profile/bin`,
    `darwin-rebuild` from `/run/current-system/sw/bin`, fish stays Homebrew.
  - [x] macOS defaults / Dock / Finder / keyboard / trackpad: declared via
    `system.defaults`, capturing the machine's current intentional settings
    (interface style, key repeat, Dock autohide/tilesize/recents, Finder view
    and desktop icons, trackpad tap/right-click). Values mirror current state,
    so activation was a no-op baseline. Tested clean.
  - [x] launchd user services: nothing to migrate. The only user LaunchAgents
    are Dropbox's own app-managed agents (`com.dropbox.*`); there are no
    custom/personal agents. Add `launchd.user.agents.<name>` here if a
    background job is ever needed.
  - [x] Touch ID for sudo: `security.pam.services.sudo_local.touchIdAuth = true`
    plus `reattach = true` (pam_reattach) so the prompt also works inside
    tmux/screen. `/etc/pam.d/sudo` already includes `sudo_local`. Tested clean.
  - Known cosmetic churn: each switch prints "Uninstalled 1 formula" because
    Homebrew renamed `sdl2` -> `sdl2-compat` but the keg is still installed
    under the old name (`Cellar/sdl2`). cleanup mis-matches it against
    mpv/ffmpeg's `sdl2` dependency and reports removing it, but it persists and
    mpv keeps working. Clear it with `brew upgrade sdl2-compat` (one-time keg
    rename migration) if the noise is bothersome.
- [x] Conservative first cut to limit blast radius:
  - `nix.enable = false` (upstream installer keeps managing the nix-daemon and
    `/etc/nix/nix.conf`).
  - `home-manager.useUserPackages = false` so `home.packages` stay in
    `~/.nix-profile/bin`, matching Linux and the fish PATH design.
  - fish stays Homebrew-managed as the login shell; nix-darwin does not touch
    `/etc/shells`.
- [x] Made Homebrew fully declarative (`homebrew.onActivation.cleanup =
  "uninstall"`):
  - Curated the declared brews/casks/taps to the wanted set.
  - Dry-ran `brew bundle cleanup` (taps trusted first) to confirm the exact
    removal set before flipping.
  - macOS activation tested: undeclared packages/taps removed; kept packages
    and their dependencies retained.
  - Tap-trust is machine-local: trust the declared third-party taps once per
    machine (`brew trust d12frosted/emacs-plus dopplerhq/cli oven-sh/bun`) or
    the switch fails on `brew bundle --cleanup`.
  - Known cosmetic quirk: Homebrew core renamed `sdl2` -> `sdl2-compat`, so
    cleanup keeps reporting it would uninstall `sdl2-compat`. That name is not
    installed (the real `sdl2` keg, used by mpv/ffmpeg/openai-whisper, is
    retained), so it is a harmless no-op. Resolve later by migrating the keg
    (e.g. reinstall mpv/ffmpeg/openai-whisper).
- [ ] Next: optionally migrate launchd user services, or expand
  `system.defaults` coverage as preferences change.

### 7. Improve Host Structure

- [x] Decide whether `linux` and `mac` should stay as the public config names.
  Kept as the stable, primary names for the daily workflow.
- [x] Optionally add host-specific aliases later:
  - `x1-carbon` (identical to `linux`)
  - `macbook-air` (identical to `mac`)
- [x] Keep common config in `nix/home-manager/common.nix`.
- [x] Keep OS-level home config in:
  - `nix/home-manager/linux.nix`
  - `nix/home-manager/darwin.nix`
- [x] Keep host-specific overrides in:
  - `nix/hosts/x1-carbon/home.nix`
  - `nix/hosts/macbook-air/home.nix`

### 8. Reproducibility Improvements

- [x] Gradually replace out-of-store links with store-backed files where the
  files are static and should not be edited by applications.
  - [x] First batch (Linux-only, store-backed): `.XCompose`,
    `voxtype/config.toml`, `elephant/websearch.toml`,
    `elephant/google-favicon.png`, and the WirePlumber Shure MV7 override.
  - [x] Second batch: `mpv/mpv.conf` + `mpv/input.conf` (Linux; `scripts/`,
    `bin/`, `script-opts/` stay linked). `tmux/.tmux.conf` was initially
    store-backed here, then superseded by typed `programs.tmux`.
  - [x] Third batch: shared `.hunspell_default`; Linux-only Typora user config,
    `rtorrent.rc`, Makima TOMLs, mpv `script-opts/*.conf`, and Hypr/Omarchy
    `hypr/*.conf` files. Mutable/executable helper trees stay linked.
  - [x] Fourth batch: Claude `settings.json` and `commands/` are store-backed;
    app/plugin state remains outside this repo.
  - [x] Fifth batch: `~/bin` scripts, Fish completions/helpers, Pi static
    config, Neovim Lua config, Hypr helper scripts, and mpv helper trees are
    store-backed. Mutable lock/state files remain linked.
  - [x] Linux activation tested (links resolve into `/nix/store`).
  - [x] macOS activation tested for the old shared `tmux/.tmux.conf` link
    before the later `programs.tmux` migration.
- [ ] Keep out-of-store links for mutable directories such as Emacs packages,
  agent skills, app state, and plugin trees unless there is a better owner.
  Claude settings/commands and other static helpers are now store-backed; keep
  app-generated state outside this repo. Remaining intentional bridge links are
  mostly mutable/plugin-like: `.emacs.d`, Fish `fish_variables`/`local.fish`,
  Neovim `lazy-lock.json`, agent skills, and mutable Pi settings/extensions/skills.
- [x] Consider adding a small check script that runs:

  ```sh
  nix build .#homeConfigurations.linux.activationPackage
  nix eval .#homeConfigurations.linux.config.home.stateVersion
  ```

  - [x] Added `nix/check.sh`: builds the native host's activation package,
    eval-checks the other host, and prints `stateVersion` for both.

- [ ] Consider a CI check later, but only after the flake can evaluate cleanly
  for both Linux and macOS in the chosen environment.

## Recommended Migration Sequence

1. [x] Tmux: migrate `.tmux.conf` to `programs.tmux`, keep `package = null`,
   and replace TPM plugins with Nix-provided tmux plugins.
2. [x] Remaining Fish static functions: move pure functions such as
   `fish_prompt`, `fish_greeting`, `cd`, `ls`, `l.`, and `btmm` to
   `programs.fish.functions`; keep `fish_variables` and `local.fish` as local
   mutable bridge links.
3. [x] Typed shell tool modules: convert manual hooks to `programs.direnv` and
   `programs.zoxide` (with `--cmd j`); evaluate `programs.mise` only after PATH
   ordering is rechecked.
4. [x] Small static one-file configs: store-back or type-manage low-risk files
   such as `emacs/.hunspell_default`, `rtorrent.rc`, Typora user config,
   Makima TOMLs, mpv script options, Hypr/Omarchy `hypr/*.conf` files, and
   Claude settings/commands.
5. [x] Portable CLI packages: Nix-own additive cross-platform tools such as
   `sesh`, `tree`, `pwgen`, `calc`, `fzf`, `fd`, `ripgrep`, and `jq` while
   preserving the native-tool PATH priority rule.
6. [x] Hypr/Omarchy configs: store-back static `hypr/*.conf` and helper
   scripts from `linux.nix`; avoid full typed Hyprland until it is clear it
   will not fight Omarchy defaults/updates.

For each step: build/evaluate both hosts, activate one machine at a time, test
interactive behavior, then commit the logical migration before continuing.

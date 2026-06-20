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
  in `nix/darwin/configuration.nix`. Conservative defaults: `nix.enable =
  false`, `homebrew.onActivation.cleanup = "none"`, fish stays Homebrew-managed
  as the login shell.
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

- [ ] Fish:
  - [x] Split the bridge from one whole `.config/fish` directory link to
    explicit Fish file/directory links.
  - [x] Move `config.fish` plus simple aliases/abbreviations to
    `programs.fish`.
  - [x] Keep machine-specific PATH or environment details explicit (PATH,
    Omarchy, Homebrew/CPATH, Obsidian, grok now expressed in
    `programs.fish.shellInit`).
  - [x] Inline `exports.fish` and `colors.fish` into `programs.fish` and drop
    those linked files.
  - [x] Avoid breaking interactive startup; test by opening a new shell after
    activation.
    - [x] Linux activation tested.
    - [x] macOS activation tested.

- [ ] Tmux:
  - Evaluate `programs.tmux`.
  - Keep TPM/plugin behavior stable before replacing the whole `.tmux` link.
  - This may stay as a link if plugin state makes typed config less useful.

- [ ] Shell environment:
  - [x] Move portable static editor/pager/color/zoxide variables to
    `home.sessionVariables`.
  - [x] Keep PATH and OS-specific startup logic in Fish, but generated from
    `programs.fish` rather than a linked file.
  - [x] Linux activation tested.
  - [x] macOS activation tested.
  - [x] App-specific startup (zoxide/mise/direnv/orbstack) lives in
    `programs.fish.shellInit`.

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

- [x] Decide which CLI tools should be installed by Home Manager as
  `home.packages`. Started `home.packages` in `common.nix`.
  - [x] `direnv` (referenced by fish startup; was missing on Linux, so purely
    additive there).
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

- [ ] Keep Omarchy/Hyprland config under `linux.nix`.
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
  - [ ] macOS defaults / Dock / Finder / keyboard: not set yet.
  - [ ] launchd services: not migrated yet.
- [x] Conservative first cut to limit blast radius:
  - `nix.enable = false` (upstream installer keeps managing the nix-daemon and
    `/etc/nix/nix.conf`).
  - `homebrew.onActivation.cleanup = "none"` (no surprise uninstalls).
  - `home-manager.useUserPackages = false` so `home.packages` stay in
    `~/.nix-profile/bin`, matching Linux and the fish PATH design.
  - fish stays Homebrew-managed as the login shell; nix-darwin does not touch
    `/etc/shells`.
- [ ] Next: consider tightening `homebrew.onActivation.cleanup` to
  `"uninstall"` once the declared lists are confirmed to match the machine,
  then optionally add `system.defaults`.

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
  - [x] Second batch: `tmux/.tmux.conf` (shared; `.tmux` dir stays linked for
    TPM plugins) and `mpv/mpv.conf` + `mpv/input.conf` (Linux; `scripts/`,
    `bin/`, `script-opts/` stay linked).
  - [x] Linux activation tested (links resolve into `/nix/store`).
  - [x] macOS activation tested for the shared `tmux/.tmux.conf`.
- [ ] Keep out-of-store links for mutable directories such as Emacs packages,
  agent skills, app state, and plugin trees unless there is a better owner.
- [x] Consider adding a small check script that runs:

  ```sh
  nix build .#homeConfigurations.linux.activationPackage
  nix eval .#homeConfigurations.linux.config.home.stateVersion
  ```

  - [x] Added `nix/check.sh`: builds the native host's activation package,
    eval-checks the other host, and prints `stateVersion` for both.

- [ ] Consider a CI check later, but only after the flake can evaluate cleanly
  for both Linux and macOS in the chosen environment.

## Good Next Step

The next practical migration is probably Fish or the shell environment.

Suggested approach:

1. Read `fish/.config/fish`.
2. Identify pure settings, aliases, abbreviations, and environment variables.
3. Move only the obvious static pieces into `programs.fish`.
4. Leave complex startup code linked until it is clear that Home Manager makes
   it simpler.
5. Build and dry-run both hosts.
6. Activate one machine at a time.
7. Commit.

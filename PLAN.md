# Nix/Home Manager Migration Plan

This is the working plan for finishing the migration from GNU Stow to Nix +
Home Manager across:

- `linux`: ThinkPad X1 Carbon Gen 13, Omarchy Linux
- `mac`: MacBook Air, macOS

## Current State

- Nix is installed on both machines.
- Flakes are enabled on both machines.
- Standalone Home Manager works on both machines.
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

Use the machine-specific Home Manager config:

```sh
home-manager switch --flake ~/src/mark/tilde#linux
home-manager switch --flake ~/src/mark/tilde#mac
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
  - [ ] Keep machine-specific PATH or environment details explicit.
  - [ ] Avoid breaking interactive startup; test by opening a new shell after
    activation.
    - [x] Linux activation tested.
    - [x] macOS activation tested.

- [ ] Tmux:
  - Evaluate `programs.tmux`.
  - Keep TPM/plugin behavior stable before replacing the whole `.tmux` link.
  - This may stay as a link if plugin state makes typed config less useful.

- [ ] Shell environment:
  - Move simple exported variables to `home.sessionVariables` where portable.
  - Keep app-specific startup logic in fish if Home Manager would obscure it.

- [ ] Simple one-file configs:
  - Convert files only when generated Nix is easier to read than the original.
  - Good candidates are small static config files with no app-managed state.

### 4. Package Management Strategy

Do not blindly move every package into Nix.

- [ ] Decide which CLI tools should be installed by Home Manager as
  `home.packages`.
- [ ] Keep OS integration packages in the native package manager when that is
  more practical:
  - Linux system/desktop packages can remain in `packages.txt` and `aur.txt`
    until there is a clear reason to move them.
  - macOS GUI/Homebrew-managed apps can remain in `macos/Brewfile` until
    nix-darwin is introduced.
- [ ] Start with portable CLI tools that are the same on Linux and macOS.
- [ ] Avoid changing the owner of critical tools like `git`, `gh`, shells, or
  desktop services until the tradeoff is explicit.

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
- [ ] Decide whether `voxtype.service` should become a typed
  `systemd.user.services` definition instead of a linked unit file.
- [ ] Document the remaining `system/` workflow for `/etc` clearly:

  ```sh
  sudo stow -t / system
  ```

- [ ] Longer-term option: move Linux system config to NixOS only if the laptop
  moves from Omarchy/Arch to NixOS.

### 6. macOS-Only Work

- [ ] Keep `macos/Brewfile` linked until there is a clear nix-darwin plan.
- [ ] Decide whether to add nix-darwin for:
  - Homebrew orchestration
  - macOS defaults
  - Dock/Finder/keyboard settings
  - launchd services
- [ ] If nix-darwin is introduced, keep it separate from standalone Home
  Manager at first and migrate one concern at a time.

### 7. Improve Host Structure

- [ ] Decide whether `linux` and `mac` should stay as the public config names.
- [ ] Optionally add host-specific aliases later:
  - `x1-carbon`
  - `macbook-air`
- [ ] Keep common config in `nix/home-manager/common.nix`.
- [ ] Keep OS-level home config in:
  - `nix/home-manager/linux.nix`
  - `nix/home-manager/darwin.nix`
- [ ] Keep host-specific overrides in:
  - `nix/hosts/x1-carbon/home.nix`
  - `nix/hosts/macbook-air/home.nix`

### 8. Reproducibility Improvements

- [ ] Gradually replace out-of-store links with store-backed files where the
  files are static and should not be edited by applications.
- [ ] Keep out-of-store links for mutable directories such as Emacs packages,
  agent skills, app state, and plugin trees unless there is a better owner.
- [ ] Consider adding a small check script that runs:

  ```sh
  nix build .#homeConfigurations.linux.activationPackage
  nix eval .#homeConfigurations.linux.config.home.stateVersion
  ```

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

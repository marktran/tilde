# NixOS on exe.dev

`configuration.nix` here is a **rescued copy** of `/etc/nixos/configuration.nix`
from the exe.dev VM `jacquie`, taken 2026-08-23. It is not wired into
`flake.nix` yet — it is checked in so the setup survives the loss of that VM.

## Why it was rescued

`jacquie` runs NixOS 26.05pre-git (Yarara) on exe.dev with zero failed systemd
units. It was created from an image named `exe-nixos-exedev-<uuid>:24h`, and
that `24h` tag means the image no longer exists. The exe.dev CLI has no image
registry, so the VM's disk was the only surviving copy of this configuration.

## What the configuration encodes

exe.dev boots a container image onto a block device using a kernel it supplies,
and runs the image's `CMD` as PID 1. This config follows the
`profiles/docker-container.nix` pattern: `/init` is the NixOS stage-2 init, and
`nixos-rebuild switch` re-points it, so rebuilds survive reboots.

The non-obvious parts are all concessions to `exe-init`, which sets up the guest
before handing PID 1 to NixOS:

- `exe-init` configures the NIC, routes, DNS, hostname, and `/etc/hosts`, so the
  config disables DHCP, `resolvconf`, and `environment.etc.hosts`.
- exe.dev's SSH ingress is an **embedded sshd outside NixOS**. Hence
  `services.openssh.enable = false`, `users.allowNoPasswordLogin = true`, and a
  stub `sshd` privsep user that must survive NixOS activation rewriting
  `/etc/passwd`.
- That SSH server hands in a conventional PATH, so an activation script installs
  a `/bin/exe-shell` wrapper (aliased to `/bin/bash` and `/bin/sh`) that adds the
  NixOS system profile for both interactive and command-mode SSH.
- exe.dev injects `/exe.dev/{bin,lib,etc,var}`, which is self-contained — the
  usual FHS problem with foreign binaries on NixOS does not bite here.

## Provisioning new VMs

exe.dev's `cp` clones a VM including its disk, so no published image is needed:

```sh
ssh exe.dev cp jacquie <new-name>
```

Copies drift from a common ancestor, so treat this file as the source of truth
and use `nixos-rebuild` on each VM rather than the golden disk. `nixos-golden`
exists as a warm spare of `jacquie`.

The alternative, if image ownership is ever wanted, is building
`config.system.build.tarball` from this configuration and pushing it to a
registry, then `ssh exe.dev new --image=… --registry-auth=…`.

## Validated behavior (2026-08-23)

Tested on `nixos-lab`, a throwaway `cp` of `jacquie`.

**The PATH wrapper must prepend, not replace.** As rescued, `exe-shell`
assigned `PATH` unconditionally. Because `/bin/sh` and `/bin/bash` are symlinks
to it, every `sh -c`, every `#!/bin/sh` script, and every process supervisor
lost the caller's environment. Devbox's process-compose failed with
`sh: line 1: exec: postgres: not found` on a loop. After switching to a
prepend, `devbox run setup` for a Rails app completes end to end with the
default `SHELL=/bin/exe-shell`.

Note when debugging this: a failed process-compose stays alive in a restart
loop and is reused by later runs, so it reproduces the old failure after the
fix is applied. Kill it (`pkill -f process-compose`) before re-testing.

**nix-ld makes prebuilt binaries work.** Without it there is no
`/lib64/ld-linux-x86-64.so.2`, so anything shipped as a prebuilt glibc binary
dies with `cannot execute: required file not found` -- `curl | sh` installers,
coding-agent distributions, and the VS Code Remote-SSH server. With
`programs.nix-ld.enable = true`, official upstream Node and a GitHub-released
`fd` both run unmodified. Same tool from nixpkgs installs in ~16s, so prefer
that where it exists.

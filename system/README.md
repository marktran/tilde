# system

System-level (`/etc`) files for this machine (Lenovo ThinkPad X1 Carbon).
These target the filesystem **root**, which standalone Home Manager cannot own
on Omarchy/Arch, so they are deployed by `system/install.sh`:

```sh
sudo system/install.sh      # deploy (or: make system)
system/install.sh --check   # dry run, show drift (or: make system-diff)
```

The script deploys each file by the right mechanism for when it is read:

- **Real files** for early-boot / security configs (`modprobe.d`, the Limine
  boot entry, the makima systemd override). A symlink into `/home` is
  unreadable in early boot and unsafe for PAM, so these are installed as copies.
- **Symlinks** from this checkout for runtime configs (the acpid events), so
  edits are live without re-running the installer.
- `etc/pam.d/sudo` is a **reviewed manual step**: the installer never
  overwrites it (a broken PAM config can lock out sudo); it prints a diff +
  apply command when it drifts.

This replaced the old `sudo stow -t / system` workflow; GNU Stow is no longer
used anywhere in this repo.

## Contents

ThinkPad F8 / "Mode" key → light/dark toggle (handled in userspace via acpid):

- `etc/acpi/events/thinkpad-mode-2024` (HKEY `0x131f`) and
  `etc/acpi/events/thinkpad-mode-2025` (HKEY `0x1401`) — acpid event rules that
  run `~/bin/toggle-color-scheme` as user `mark`. These are **live symlinks**
  into this checkout; after deploying, reload acpid:
  `sudo systemctl restart acpid`.
- `etc/modprobe.d/thinkpad_acpi.conf` — `profile_force=-1` so `thinkpad_acpi`
  releases the Mode key's HKEY event to acpid instead of cycling power profiles.
- `etc/limine-entry-tool.d/thinkpad-acpi.conf` — the same `profile_force=-1`
  applied via the kernel cmdline (Limine boot entries).

Other files:

- `etc/pam.d/sudo` — PAM sudo config enabling U2F (`pam_u2f`) and fingerprint
  (`pam_fprintd`) auth. A **reviewed manual step**: kept as a real file
  (security-sensitive), never auto-applied by `install.sh`.
- `etc/systemd/system/makima.service.d/override.conf` — runs the `makima` input
  remapper as user `mark` / group `input` with `MAKIMA_CONFIG`.

## Notes

- `install.sh` is idempotent: re-running only changes files that drifted, and
  reminds you to `systemctl restart acpid` / `daemon-reload` when relevant.

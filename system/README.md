# system

System-level (`/etc`) files for this machine (Lenovo ThinkPad X1 Carbon).
Unlike the home-directory packages, this one targets the filesystem **root**:

```sh
sudo stow -t / system
```

Keep it as its own package: its files target `/`, so it must **not** be folded
into the `~`-targeted `linux` package — mixing stow targets breaks clean stowing.

## Contents

ThinkPad F8 / "Mode" key → light/dark toggle (handled in userspace via acpid):

- `etc/acpi/events/thinkpad-mode-2024` (HKEY `0x131f`) and
  `etc/acpi/events/thinkpad-mode-2025` (HKEY `0x1401`) — acpid event rules that
  run `~/bin/toggle-color-scheme` as user `mark`. These are **live symlinks**
  managed by stow; after (re)stowing, reload acpid:
  `sudo systemctl restart acpid`.
- `etc/modprobe.d/thinkpad_acpi.conf` — `profile_force=-1` so `thinkpad_acpi`
  releases the Mode key's HKEY event to acpid instead of cycling power profiles.
- `etc/limine-entry-tool.d/thinkpad-acpi.conf` — the same `profile_force=-1`
  applied via the kernel cmdline (Limine boot entries).

Other files:

- `etc/pam.d/sudo` — PAM sudo config enabling U2F (`pam_u2f`) and fingerprint
  (`pam_fprintd`) auth. Treat as a **reference backup**: `/etc/pam.d/sudo` should
  remain a real file (security-sensitive), not a symlink.
- `etc/systemd/system/makima.service.d/override.conf` — runs the `makima` input
  remapper as user `mark` / group `input` with `MAKIMA_CONFIG`.

## Notes

- `README.md` is excluded from stow via `.stow-local-ignore` (which also re-lists
  Stow's built-in defaults, since defining that file replaces them).

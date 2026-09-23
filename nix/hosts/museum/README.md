# Museum VM maintenance

The `museum` Home Manager profile runs `museum-maintenance.service` every five
minutes. It runs as the login user, not root, and does two things:

- Sends `TERM` to that user's `process-compose` and PostgreSQL processes whose
  current directory is a **deleted** checkout under
  `~/.herdr/worktrees/museum/`. Live worktrees and the main checkout are excluded.
- Rotates the shared `/tmp/process-compose-$USER.log` and main/worktree
  `.devbox/compose.log` files above 20 MiB, retaining two compressed backups.
  `copytruncate` preserves open file descriptors. This is a periodic bound, not
  a hard quota; logs can grow between checks and a few log lines can be lost
  during copying/truncation.

This is a fallback, not a replacement for teardown. In Museum, run
`script/worktree-teardown` **from the linked worktree before deleting it**. This
stops its whole Devbox process manager, not only PostgreSQL. The Museum
`process-compose.yaml` also caps PostgreSQL restarts. Existing supervisors must
be restarted to pick up that configuration; the VM safeguards cover them in
the meantime.

The user manager must survive logout. Museum's `script/exe-setup.sh` enables
lingering; on an existing VM check `loginctl show-user "$USER" -p Linger`.

```sh
# Apply on museum.exe.xyz, from its tilde checkout (not the laptop profile):
make dry-run HOST=museum
make switch HOST=museum

systemctl --user list-timers museum-maintenance.timer
systemctl --user start museum-maintenance.service
journalctl --user -u museum-maintenance.service

# Read-only candidate inspection, using Ruby from the Devbox environment:
cd ~/src/vhm/museum
devbox run -- ruby ~/src/mark/tilde/nix/hosts/museum/reap-stale-services.rb --dry-run
```

For non-interactive SSH, set `XDG_RUNTIME_DIR=/run/user/$(id -u)` if the user bus
is not discovered automatically. Do not run the reaper as root.

## Regression check

```sh
# Requires the minitest gem (available in the mise-managed Ruby environment).
mise exec ruby -- ruby nix/hosts/museum/reap-stale-services_test.rb
```

## September 2026 incident

32 supervisors survived deletion of their worktrees and retried missing
PostgreSQL commands once per second. Deleted-but-open `.devbox/compose.log`
files occupied 12.34 GiB; the shared process-compose log occupied 9.89 GiB. The
50 GiB root filesystem had no space available to the login user. Stopping only
the stale supervisors and truncating the shared log restored about 23 GiB of
available space without restarting the main database.

Use `lsof +L1` as well as `du` when investigating disk usage: unlinked files
still held open by a process are absent from `du` but consume filesystem space.

#!/usr/bin/env bash
# Deploy this machine's privileged /etc files (Lenovo ThinkPad X1 Carbon).
#
# Replaces the old `sudo stow -t / system` workflow. Files are deployed by the
# right mechanism for when they are read:
#   - REAL files for early-boot / security configs. A symlink into /home is
#     unreadable in early boot (modprobe, bootloader) and unsafe for PAM.
#   - SYMLINKS for runtime configs (acpid events), so edits are live.
#
# /etc/pam.d/sudo is intentionally NOT auto-applied (a broken PAM config can
# lock out sudo); it is a reviewed manual step, surfaced below.
#
# Usage:
#   sudo linux/install.sh           # deploy (real files + acpid symlinks)
#   linux/install.sh --check        # dry run: show changes, write nothing
#   (or: make system / make system-diff)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

if [ "$CHECK" -eq 0 ] && [ "$(id -u)" -ne 0 ]; then
  echo "Must run as root (writes to /etc). Try: sudo $0" >&2
  exit 1
fi

# Read in early boot / security-sensitive: install as real copies (mode 644).
REAL_FILES=(
  etc/modprobe.d/thinkpad_acpi.conf
  etc/limine-entry-tool.d/thinkpad-acpi.conf
  etc/systemd/system/makima.service.d/override.conf
)

# Read at runtime by acpid: symlink from the checkout so edits are live.
LINK_FILES=(
  etc/acpi/events/thinkpad-mode-2024
  etc/acpi/events/thinkpad-mode-2025
)

changed=0

install_real() {
  local rel="$1"
  local src="$SCRIPT_DIR/$rel"
  local dst="/$rel"
  if [ -f "$dst" ] && [ ! -L "$dst" ] && cmp -s "$src" "$dst"; then
    return 0
  fi
  changed=1
  if [ "$CHECK" -eq 1 ]; then
    echo "would install (real file): $dst"
    return 0
  fi
  # Clear stale Stow-era symlinks on the path: `stow` folded whole dirs (e.g.
  # /etc/systemd/system/makima.service.d) and files into symlinks into the
  # checkout, which now dangle. Replace them with a real dir + real file.
  local dir
  dir="$(dirname "$dst")"
  [ -L "$dir" ] && rm -f "$dir"
  [ -L "$dst" ] && rm -f "$dst"
  mkdir -p "$dir"
  install -m 644 "$src" "$dst"
  echo "installed (real file): $dst"
}

link_file() {
  local rel="$1"
  local src="$SCRIPT_DIR/$rel"
  local dst="/$rel"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
    return 0
  fi
  changed=1
  if [ "$CHECK" -eq 1 ]; then
    echo "would symlink: $dst -> $src"
    return 0
  fi
  local dir
  dir="$(dirname "$dst")"
  [ -L "$dir" ] && rm -f "$dir"
  mkdir -p "$dir"
  ln -sfn "$src" "$dst"
  echo "symlinked: $dst -> $src"
}

for f in "${REAL_FILES[@]}"; do install_real "$f"; done
for f in "${LINK_FILES[@]}"; do link_file "$f"; done

# Security-sensitive: never auto-overwritten. Surface drift for manual review.
if ! cmp -s "$SCRIPT_DIR/etc/pam.d/sudo" /etc/pam.d/sudo 2>/dev/null; then
  echo
  echo "NOTE: /etc/pam.d/sudo differs from the repo reference (not auto-applied)."
  echo "  Review, then apply manually (a broken PAM config can lock out sudo):"
  echo "    diff -u /etc/pam.d/sudo $SCRIPT_DIR/etc/pam.d/sudo"
  echo "    sudo install -m 644 $SCRIPT_DIR/etc/pam.d/sudo /etc/pam.d/sudo"
fi

if [ "$CHECK" -eq 1 ]; then
  [ "$changed" -eq 0 ] && echo "/etc is up to date with the repo."
  exit 0
fi

if [ "$changed" -eq 1 ]; then
  echo
  echo "Done. If acpid rules changed:   sudo systemctl restart acpid"
  echo "      If the makima override changed: sudo systemctl daemon-reload && sudo systemctl restart makima"
else
  echo "/etc already up to date; nothing to do."
fi

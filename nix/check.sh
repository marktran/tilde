#!/usr/bin/env bash
# Quick sanity check for the Home Manager flake.
#
# - Builds the activation package for the *native* host (Linux or macOS).
# - Evaluates the other host's activation package (eval-only; this catches
#   evaluation/type errors without needing a cross-platform builder).
# - Prints home.stateVersion for both hosts.
#
# Usage:
#   nix/check.sh [linux|mac|both]   (default: both)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO"

NIX_FLAGS=(--no-warn-dirty)

case "$(uname -s)" in
  Linux) NATIVE=linux ;;
  Darwin) NATIVE=mac ;;
  *) echo "Unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

want="${1:-both}"
case "$want" in
  linux) HOSTS=(linux) ;;
  mac) HOSTS=(mac) ;;
  both) HOSTS=(linux mac) ;;
  *) echo "Usage: $0 [linux|mac|both]" >&2; exit 1 ;;
esac

fail=0

for host in "${HOSTS[@]}"; do
  printf '\n===== %s =====\n' "$host"

  printf 'stateVersion: '
  if ! nix eval "${NIX_FLAGS[@]}" --raw ".#homeConfigurations.${host}.config.home.stateVersion"; then
    echo "ERROR: failed to evaluate stateVersion for ${host}"
    fail=1
    continue
  fi
  echo

  if [ "$host" = "$NATIVE" ]; then
    echo "building activation package (native)..."
    if nix build "${NIX_FLAGS[@]}" --no-link \
        ".#homeConfigurations.${host}.activationPackage"; then
      echo "OK: ${host} activation package builds"
    else
      echo "ERROR: ${host} activation package failed to build"
      fail=1
    fi
  else
    echo "evaluating activation package (non-native, eval-only)..."
    if nix eval "${NIX_FLAGS[@]}" --raw \
        ".#homeConfigurations.${host}.activationPackage.drvPath" >/dev/null; then
      echo "OK: ${host} activation package evaluates"
    else
      echo "ERROR: ${host} activation package failed to evaluate"
      fail=1
    fi
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
fi
exit "$fail"

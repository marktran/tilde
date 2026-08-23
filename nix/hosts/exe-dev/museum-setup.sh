#!/usr/bin/env bash
#
# Provision an exe.dev NixOS VM for Museum development.
#
# Lives here rather than in the Museum repo: none of this is application
# config, it is host setup for one deployment target. Museum itself needs no
# changes to run on exe.dev -- Rails and vite_ruby both take these from the
# environment.
#
#   ssh exe.dev cp nixos-golden <name> --disk=50GB
#   rsync -az --exclude node_modules --exclude .devbox ~/src/vhm/museum/ <name>.exe.xyz:src/museum/
#   scp museum-setup.sh <name>.exe.xyz:/tmp/ && ssh <name>.exe.xyz /tmp/museum-setup.sh
#   ssh exe.dev share port <name> 3000
#
# Then: ssh <name>.exe.xyz, cd src/museum, devbox run dev
set -euo pipefail

CHECKOUT="${MUSEUM_CHECKOUT:-$HOME/src/museum}"
ENV_FILE="$HOME/.config/exe-dev/museum-env.sh"

command -v devbox >/dev/null 2>&1 || curl -fsSL https://get.jetify.com/devbox | FORCE=1 bash
export PATH="/usr/local/bin:$PATH"

mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" <<'ENVEOF'
# Museum on an exe.dev VM. Sourced from ~/.bashrc; not part of the repo.

# Rails' host allowlist rejects the *.exe.xyz hostname the proxy forwards.
export RAILS_DEVELOPMENT_HOSTS=.exe.xyz

# The exe.dev proxy reaches the VM over its NIC, not loopback. Rails' server
# command reads this (railties: ENV.fetch("BINDING", default_host)).
export BINDING=0.0.0.0

# config/vite.json sets skipProxy for local development, which points the
# browser straight at port 3036. On a VM it is simpler to expose one port and
# let Rails proxy Vite, so assets and HMR ride the Rails port.
export VITE_RUBY_SKIP_PROXY=false
ENVEOF

grep -q 'museum-env.sh' "$HOME/.bashrc" 2>/dev/null ||
  printf '\n[ -f %s ] && . %s\n' "$ENV_FILE" "$ENV_FILE" >> "$HOME/.bashrc"

# shellcheck source=/dev/null
. "$ENV_FILE"

cd "$CHECKOUT"
devbox run setup
echo "MUSEUM-SETUP-COMPLETE"

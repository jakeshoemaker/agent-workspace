#!/usr/bin/env bash
# Routine package and tool updates. Safe-ish to re-run.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

refuse_root "update"
need_sudo "apt upgrade"

export DEBIAN_FRONTEND=noninteractive

log "apt update && upgrade"
sudo apt-get update -y
sudo apt-get upgrade -y

if command -v uv >/dev/null 2>&1; then
  log "uv self update"
  uv self update || warn "uv self update failed (non-fatal)"
fi

if command -v docker >/dev/null 2>&1; then
  log "docker: no auto prune in update (run manually if needed)"
  log "  docker system prune -af   # DESTRUCTIVE: removes unused images/containers"
fi

if command -v tailscale >/dev/null 2>&1; then
  log "tailscale status (informational)"
  tailscale status || warn "tailscale status failed"
fi

log "update complete — consider: sudo reboot  # if kernel upgraded"

#!/usr/bin/env bash
# Install Tailscale on Ubuntu and start the daemon.
# Authentication is interactive (browser/URL) — agents must not invent auth keys here.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

refuse_root "install-tailscale"
need_sudo "install Tailscale"

if command -v tailscale >/dev/null 2>&1; then
  log "tailscale already installed: $(tailscale version 2>/dev/null | head -n1 || true)"
else
  if ! is_ubuntu; then
    die "Tailscale install expects Ubuntu. See https://tailscale.com/download"
  fi
  export DEBIAN_FRONTEND=noninteractive
  log "install Tailscale via official install script"
  # Vendor install script from tailscale.com; pin to https and review on change.
  curl -fsSL https://tailscale.com/install.sh | sudo sh
fi

log "enable tailscaled"
sudo systemctl enable --now tailscaled

if tailscale status >/dev/null 2>&1; then
  log "already authenticated:"
  tailscale status || true
else
  log "starting interactive login (opens auth URL)"
  warn "Complete login in a browser. Prefer a tag/ACL that limits this node."
  # --ssh is optional; we use classic sshd. Omit Tailscale SSH unless you opt in later.
  sudo tailscale up --accept-dns=true
  tailscale status || true
fi

log "Tailscale IPs:"
tailscale ip -4 2>/dev/null || true
tailscale ip -6 2>/dev/null || true

log "install-tailscale complete"
log "From your laptop: ssh ${USER}@$(tailscale ip -4 2>/dev/null || echo '<tailscale-ip>')"

#!/usr/bin/env bash
# Baseline packages for an Ubuntu Server agent workspace.
# Safe to re-run. Does not install Docker/Tailscale (separate recipes).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

refuse_root "bootstrap (will sudo for apt only)"
need_sudo "apt install baseline packages"

if ! is_ubuntu; then
  warn "This script targets Ubuntu/Debian. Continuing anyway."
fi

export DEBIAN_FRONTEND=noninteractive

log "apt update"
sudo apt-get update -y

log "install baseline packages"
# Keep the list boring and well-supported from Ubuntu repos.
sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  wget \
  git \
  gnupg \
  jq \
  unzip \
  zip \
  tar \
  tmux \
  htop \
  rsync \
  build-essential \
  pkg-config \
  openssh-client \
  openssh-server \
  ufw \
  fail2ban \
  unattended-upgrades \
  software-properties-common \
  apt-transport-https \
  lsb-release \
  net-tools \
  dnsutils \
  tree \
  ripgrep \
  fd-find \
  bat \
  python3 \
  python3-venv \
  python3-pip

# Ubuntu names fd/bat as fdfind/batcat; optional convenience links in ~/.local/bin
mkdir -p "${HOME}/.local/bin"
if command -v fdfind >/dev/null 2>&1 && [[ ! -e "${HOME}/.local/bin/fd" ]]; then
  ln -s "$(command -v fdfind)" "${HOME}/.local/bin/fd"
fi
if command -v batcat >/dev/null 2>&1 && [[ ! -e "${HOME}/.local/bin/bat" ]]; then
  ln -s "$(command -v batcat)" "${HOME}/.local/bin/bat"
fi

# Enable unattended security updates (non-interactive defaults).
if [[ -d /etc/apt/apt.conf.d ]]; then
  sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
fi

# Install just if missing (user or system).
if ! command -v just >/dev/null 2>&1; then
  log "just not found; running install-just.sh"
  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-just.sh"
else
  log "just already present: $(command -v just)"
fi

# Ensure tmux is usable.
need_cmd tmux
need_cmd git
need_cmd curl

log "bootstrap complete"
log "PATH tip: ensure ~/.local/bin is on PATH (dotfiles .profile does this)"

#!/usr/bin/env bash
# Install Docker Engine + Compose plugin on Ubuntu.
# Adds the invoking user to the docker group (effective root — trusted users only).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

refuse_root "install-docker"
need_sudo "install Docker"

if command -v docker >/dev/null 2>&1; then
  log "docker already installed: $(docker --version 2>/dev/null || true)"
else
  if ! is_ubuntu; then
    die "Docker install script expects Ubuntu. Install Docker manually, then re-run."
  fi

  export DEBIAN_FRONTEND=noninteractive
  log "install Docker prerequisites"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg

  # Official Docker apt repository (Ubuntu).
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    log "add Docker GPG key"
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  arch="$(dpkg --print-architecture)"
  codename="${VERSION_CODENAME:-}"
  [[ -n "${codename}" ]] || die "cannot determine Ubuntu codename"

  log "add Docker apt repository (${codename}/${arch})"
  echo \
    "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update -y
  log "install docker-ce and compose plugin"
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

log "enable docker service"
sudo systemctl enable --now docker

if ! groups | tr ' ' '\n' | grep -qx docker; then
  log "add ${USER} to docker group (re-login required for group to apply)"
  sudo usermod -aG docker "${USER}"
  warn "run: newgrp docker   # or log out/in before using docker without sudo"
else
  log "${USER} already in docker group"
fi

log "docker version:"
docker --version || sudo docker --version
docker compose version || sudo docker compose version

log "install-docker complete"

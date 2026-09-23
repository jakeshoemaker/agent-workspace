#!/usr/bin/env bash
# Non-destructive environment checks for agents and operators.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ok=0
bad=0

check() {
  local name="$1"
  shift
  if "$@"; then
    printf '  [ok]   %s\n' "${name}"
    ok=$((ok + 1))
  else
    printf '  [FAIL] %s\n' "${name}"
    bad=$((bad + 1))
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

bashrc_is_symlink() { [[ -L "${HOME}/.bashrc" ]]; }

tmux_conf_present() {
  [[ -f "${HOME}/.config/tmux/tmux.conf" ]] || [[ -f "${HOME}/.tmux.conf" ]]
}

ssh_dir_is_700() {
  [[ -d "${HOME}/.ssh" ]] || return 1

  local mode
  mode="$(stat -c '%a' "${HOME}/.ssh" 2>/dev/null || stat -f '%Lp' "${HOME}/.ssh")"
  [[ "${mode}" == "700" ]]
}

echo "agent-workspace doctor"
echo "host: $(hostname)  user: ${USER}  date: $(date -Is)"
echo

echo "commands"
check "git" have git
check "tmux" have tmux
check "curl" have curl
check "jq" have jq
check "just" have just
check "uv" have uv
check "docker" have docker
check "tailscale" have tailscale
check "sshd" have sshd
echo

echo "dotfiles"
check "~/.bashrc is symlink" bashrc_is_symlink
check "tmux.conf present" tmux_conf_present
check "~/.ssh is 700" ssh_dir_is_700
echo

echo "services (best-effort)"
if have systemctl; then
  check "ssh service" systemctl is-active --quiet ssh || systemctl is-active --quiet sshd
  check "docker service" systemctl is-active --quiet docker || true
  check "tailscaled" systemctl is-active --quiet tailscaled || true
fi
echo

if have docker; then
  echo "docker"
  if docker info >/dev/null 2>&1; then
    printf '  [ok]   docker info (group active)\n'
    ok=$((ok + 1))
  else
    printf '  [WARN] docker needs sudo or newgrp docker\n'
  fi
  echo
fi

if have tailscale; then
  echo "tailscale"
  tailscale status 2>/dev/null | head -n 5 || printf '  [WARN] not logged in\n'
  echo
fi

echo "summary: ${ok} ok, ${bad} fail"
if [[ "${bad}" -gt 0 ]]; then
  exit 1
fi

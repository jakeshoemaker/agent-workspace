#!/usr/bin/env bash
# Shared helpers for agent-workspace scripts.
# shellcheck shell=bash

set -euo pipefail

log()  { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# Refuse to run as root for user-scoped installs (dotfiles, uv).
refuse_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    die "run as a normal user (not root): $*"
  fi
}

# Require sudo for system changes; keep a clear audit trail.
need_sudo() {
  need_cmd sudo
  if ! sudo -n true 2>/dev/null; then
    log "sudo access required for: $*"
    sudo -v
  fi
}

is_ubuntu() {
  [[ -f /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *ubuntu* || "${ID_LIKE:-}" == *debian* ]]
}

repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  # scripts/ → repo root
  cd "${here}/.." && pwd
}

# Backup path if it exists and is not already the desired symlink.
backup_if_needed() {
  local target="$1"
  local desired="$2"
  if [[ -L "${target}" ]]; then
    local cur
    cur="$(readlink "${target}")"
    if [[ "${cur}" == "${desired}" ]]; then
      return 0
    fi
    local bak="${target}.bak.$(date +%Y%m%d%H%M%S)"
    log "backup symlink ${target} → ${bak}"
    mv "${target}" "${bak}"
    return 0
  fi
  if [[ -e "${target}" ]]; then
    local bak="${target}.bak.$(date +%Y%m%d%H%M%S)"
    log "backup ${target} → ${bak}"
    mv "${target}" "${bak}"
  fi
}

symlink_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "${dest}")"
  backup_if_needed "${dest}" "${src}"
  if [[ -L "${dest}" ]] && [[ "$(readlink "${dest}")" == "${src}" ]]; then
    log "ok ${dest}"
    return 0
  fi
  ln -s "${src}" "${dest}"
  log "linked ${dest} → ${src}"
}

#!/usr/bin/env bash
# Symlink tracked dotfiles into $HOME. Backs up existing files first.
# Does NOT link SSH private keys or ~/.ssh/config (template only).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

refuse_root "install-dotfiles"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DF="${ROOT}/dotfiles"

[[ -d "${DF}" ]] || die "missing dotfiles dir: ${DF}"

log "installing dotfiles from ${DF}"

# Files we manage (relative to dotfiles/ and $HOME).
managed=(
  ".bashrc"
  ".profile"
  ".gitconfig"
  ".config/tmux/tmux.conf"
)

for rel in "${managed[@]}"; do
  src="${DF}/${rel}"
  dest="${HOME}/${rel}"
  [[ -f "${src}" ]] || die "missing tracked file: ${src}"
  symlink_file "${src}" "${dest}"
done

# SSH config is a template — never auto-overwrite ~/.ssh/config.
example_ssh="${DF}/.ssh/config.example"
if [[ -f "${example_ssh}" ]]; then
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  if [[ ! -e "${HOME}/.ssh/config" ]]; then
    cp "${example_ssh}" "${HOME}/.ssh/config"
    chmod 600 "${HOME}/.ssh/config"
    log "created ~/.ssh/config from template (edit hosts locally)"
  else
    log "left existing ~/.ssh/config untouched (see ${example_ssh})"
  fi
fi

# Machine-local bashrc hook (untracked).
local_rc="${HOME}/.bashrc.local"
if [[ ! -f "${local_rc}" ]]; then
  cat >"${local_rc}" <<'EOF'
# Machine-local bash overrides (not tracked). Sourced from ~/.bashrc.
# Example: export AGENT_WORKSPACE_HOST=nuc-lab
EOF
  log "created ${local_rc}"
fi

log "dotfiles install complete"
log "open a new shell or: source ~/.profile && source ~/.bashrc"

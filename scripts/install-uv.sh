#!/usr/bin/env bash
# Install uv for the current user (https://github.com/astral-sh/uv).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

refuse_root "install-uv"
need_cmd curl

if command -v uv >/dev/null 2>&1; then
  log "uv already installed: $(uv --version)"
  log "run: uv self update   # when you want to refresh"
  exit 0
fi

log "installing uv to ~/.local"
curl -LsSf https://astral.sh/uv/install.sh | sh

# shellcheck disable=SC1091
if [[ -f "${HOME}/.local/bin/env" ]]; then
  # newer uv installer
  source "${HOME}/.local/bin/env" || true
fi

export PATH="${HOME}/.local/bin:${PATH}"
need_cmd uv
log "uv $(uv --version)"
log "ensure ~/.local/bin is on PATH (dotfiles .profile)"

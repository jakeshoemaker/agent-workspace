#!/usr/bin/env bash
# Install just (https://github.com/casey/just) if missing.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if command -v just >/dev/null 2>&1; then
  log "just already installed: $(just --version)"
  exit 0
fi

refuse_root "install-just (user-local binary)"
need_cmd curl
mkdir -p "${HOME}/.local/bin"

log "install just to ~/.local/bin via cargo-less official installer"
# Official prebuilt installer from casey/just releases pattern used by many projects.
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
  | bash -s -- --to "${HOME}/.local/bin"

export PATH="${HOME}/.local/bin:${PATH}"
need_cmd just
log "just $(just --version)"
log "ensure ~/.local/bin is on PATH"

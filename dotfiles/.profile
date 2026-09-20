# ~/.profile — agent-workspace (login shells)
# Sourced by display managers and ssh login shells.

# User-local binaries (just, uv, pip tools)
export PATH="${HOME}/.local/bin:${PATH}"

# If bash, pull in .bashrc for interactive convenience
if [[ -n "${BASH_VERSION:-}" ]]; then
  if [[ -f "${HOME}/.bashrc" ]]; then
    # shellcheck disable=SC1091
    . "${HOME}/.bashrc"
  fi
fi

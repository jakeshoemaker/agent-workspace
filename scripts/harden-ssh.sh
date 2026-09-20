#!/usr/bin/env bash
# Harden sshd via a drop-in config. Does not replace the whole sshd_config.
#
# PRECONDITIONS (operator must confirm):
#   1. You can log in with SSH keys (PasswordAuthentication currently may still work).
#   2. You have a recovery path (physical console, cloud serial, or second network path).
#   3. Prefer Tailscale connectivity verified before disabling password auth.
#
# Agents: do not run this unattended on a host you cannot console-recover.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

refuse_root "harden-ssh"
need_sudo "write sshd drop-in"
need_cmd sshd

DROP_IN_DIR="/etc/ssh/sshd_config.d"
DROP_IN="${DROP_IN_DIR}/60-agent-workspace-hardening.conf"

if [[ "${AGENT_WORKSPACE_CONFIRM_SSH_HARDEN:-}" != "yes" ]]; then
  cat <<'EOF'
This will install an sshd drop-in that:
  - disables password authentication
  - disables root login
  - disables kbd interactive / empty passwords
  - keeps pubkey authentication

Before continuing:
  - Verify: ssh -o PreferredAuthentications=publickey user@this-host
  - Verify recovery (console / second path)
  - Prefer: Tailscale up and reachable

Re-run with:
  AGENT_WORKSPACE_CONFIRM_SSH_HARDEN=yes just harden-ssh
EOF
  exit 1
fi

sudo mkdir -p "${DROP_IN_DIR}"

log "write ${DROP_IN}"
sudo tee "${DROP_IN}" >/dev/null <<'EOF'
# Managed by agent-workspace scripts/harden-ssh.sh
# Remove this file and reload sshd to undo.

PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
PubkeyAuthentication yes
X11Forwarding no
AllowAgentForwarding yes
AllowTcpForwarding yes
ClientAliveInterval 30
ClientAliveCountMax 6
# Optional: restrict users — uncomment and edit
# AllowUsers youruser
EOF

log "validate sshd config"
sudo sshd -t

log "reload sshd"
if systemctl is-active --quiet ssh; then
  sudo systemctl reload ssh
elif systemctl is-active --quiet sshd; then
  sudo systemctl reload sshd
else
  warn "sshd/ssh service not active; config written but not reloaded"
fi

log "SSH hardening drop-in installed"
warn "Keep this session open until you confirm a NEW key-based login works."

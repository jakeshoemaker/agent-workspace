# Security model

## Trust boundaries

| Layer | Trust | Notes |
| --- | --- | --- |
| Physical NUC | high | Console = full control |
| Tailscale network | high (your tailnet) | Use ACLs/tags; least privilege |
| LAN | medium | Prefer Tailscale; firewall LAN SSH if exposed |
| Public internet | none for SSH | Do not port-forward 22 unless unavoidable |
| This git repo | public-safe | No secrets, keys, tokens |
| `secrets/`, `local/`, `~/.ssh` | private | Host-only |

## SSH

- Public-key authentication only after `just harden-ssh`.
- No root login.
- Keep `AllowUsers` tight if multiple accounts exist.
- Optional: bind SSH to the Tailscale interface only.

Example drop-in (manual; interface name varies):

```
# /etc/ssh/sshd_config.d/70-tailscale-only.conf
# ListenAddress 100.x.y.z
```

Validate with `sudo sshd -t` and keep a console session open.

## Tailscale

- Enroll the NUC with a tag such as `tag:agent-box`.
- ACLs: only admin users/devices may SSH to that tag.
- Prefer MagicDNS names in `~/.ssh/config`.
- Tailscale SSH is **optional** and separate from OpenSSH; this repo defaults to classic `sshd`.

## Firewall (UFW)

After Tailscale is healthy, a minimal stance:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
# Optional LAN during bootstrap only:
# sudo ufw allow from 192.168.0.0/16 to any port 22
sudo ufw enable
```

Adjust interface name via `ip link | grep tailscale`.

## Docker

Membership in `docker` is root-equivalent. Only the operator account should be in that group.

## Secrets

- Never commit `.env`, API keys, PEM files, or `id_*` private keys.
- Use `secrets/` on disk (mode `0700`) or a password manager.
- `.env.example` documents names only.

## Updates

- Unattended security updates are enabled in bootstrap.
- Run `just update` periodically; reboot after kernel upgrades.

## Agent guardrails

Future agents on this host should:

1. Prefer `just` recipes and scripts in this repo over one-off `curl | sh` from unknown hosts.
2. Never disable Tailscale or sshd to "fix" connectivity without a console plan.
3. Never force-push to `main` of this repo from the NUC as a convenience.
4. Treat `AGENT_WORKSPACE_CONFIRM_SSH_HARDEN=yes` as a deliberate human gate.

# agent-workspace

Provision and maintain an **Intel NUC** (or similar small PC) as a durable, agent-friendly Ubuntu workspace.

This repo is intentionally boring: plain Git dotfiles, shell install scripts, `just`, Docker Compose, Tailscale + SSH keys, and tmux. No chezmoi, mise, NixOS, or niche dotfile frameworks.

## Goals

- One machine an operator (human or coding agent) can reach reliably over Tailscale + SSH.
- Long-lived tmux sessions so work survives disconnects.
- Reproducible baseline packages and tooling (`just`, `uv`, Docker).
- Clear split between **tracked config**, **secrets**, and **machine-local** state.
- Guardrails so a future agent can maintain the box over SSH without foot-guns.

## Recommended hardware / OS

| Item | Recommendation |
| --- | --- |
| Hardware | Intel NUC (or equivalent mini PC), 16–64 GB RAM, NVMe SSD |
| OS | **Ubuntu Server LTS** (24.04 or current LTS), minimal install |
| Network | Wired Ethernet preferred; Wi-Fi OK if stable |
| Access | Tailscale mesh + SSH public-key auth only |
| Sessions | `tmux` (attach/detach; never rely on a bare SSH shell for long jobs) |
| Containers | Docker Engine + Compose plugin |
| Tooling | `just` (task runner), `uv` (Python), Git |

**Out of scope / avoid:** desktop DE on the NUC, password SSH login, storing private keys in this repo, chezmoi/mise/NixOS.

## Security model

1. **SSH:** key-only authentication; password and root password login disabled after bootstrap.
2. **Network:** prefer Tailscale; do not expose SSH on the public internet if Tailscale is available. Optional: bind `sshd` to Tailscale IP only (see `docs/security.md`).
3. **Secrets:** live under `secrets/` (gitignored) or the host keychain / env files never committed. Tracked templates use `*.example` names.
4. **Docker:** run the daemon as root (default), add only trusted users to the `docker` group (equivalent to root). Prefer rootless only if you understand the tradeoffs.
5. **Updates:** unattended security updates enabled; full upgrade on a schedule via `just update`.
6. **Agents:** treat the NUC like production: no blind `curl | sudo bash` from untrusted URLs; prefer scripts in this repo.

## Repository layout

```
.
├── README.md                 # this file
├── Justfile                  # setup & maintenance entrypoints
├── .gitignore                # secrets, local, env
├── .env.example              # non-secret env template
├── AGENTS.md                 # notes for future agents on this box
├── docs/
│   ├── install.md            # full install sequence
│   ├── security.md           # SSH / Tailscale hardening
│   └── recovery.md           # lockout and rebuild notes
├── scripts/                  # idempotent-ish bash installers
├── dotfiles/                 # vanilla home configs (symlinked)
│   ├── .bashrc
│   ├── .profile
│   ├── .gitconfig
│   ├── .config/tmux/tmux.conf
│   └── .ssh/config.example   # copy → ~/.ssh/config (not auto-linked)
├── docker/
│   └── compose.example.yml   # starter Compose file
├── secrets/                  # NEVER commit real secrets (placeholder only)
└── local/                    # machine-only notes, hostnames, etc.
```

| Path | Tracked? | Purpose |
| --- | --- | --- |
| `dotfiles/` | yes | Shared shell/Git/tmux config |
| `scripts/`, `Justfile`, `docs/` | yes | Provisioning and ops |
| `secrets/` | no (except `.gitkeep`) | API keys, tokens, private material |
| `local/` | no (except `.gitkeep`) | Host-specific notes, IPs, nicknames |
| `~/.ssh/config` | no | Built from `config.example` + local hosts |
| `~/.ssh/id_*` | no | Keys generated on the machine or operator laptop |

## Install sequence (summary)

Detailed steps: [`docs/install.md`](docs/install.md).

1. Install **Ubuntu Server LTS** on the NUC (disk encryption optional but recommended if the box leaves a trusted location).
2. Create a non-root sudo user; enable OpenSSH server during install.
3. From a trusted laptop, copy your SSH public key: `ssh-copy-id user@nuc-lan-ip`.
4. Clone this repo: `git clone <url> ~/agent-workspace && cd ~/agent-workspace`.
5. Baseline packages: `just bootstrap` (or `./scripts/bootstrap.sh`).
6. Install Docker: `just docker`.
7. Install Tailscale: `just tailscale` → authenticate with the printed URL.
8. Harden SSH: `just harden-ssh` (after confirming key login works **and** Tailscale is up).
9. Dotfiles: `just dotfiles` (backs up existing files, then symlinks).
10. Copy `dotfiles/.ssh/config.example` → `~/.ssh/config` and adjust; never commit the result.
11. `just doctor` to verify the environment.

## Day-2 operations

```bash
just                  # list recipes
just update           # apt + common tool refresh
just doctor           # health checks
just tmux-new NAME    # start a named session
just tmux-ls          # list sessions
```

Attach over SSH:

```bash
ssh nuc
tmux attach -t main   # or: tmux new -s main
```

## Recovery

See [`docs/recovery.md`](docs/recovery.md) if you lose Tailscale, lock yourself out of SSH, or need to rebuild the disk.

**Golden rule before hardening:** keep a second path open (LAN SSH or console) until Tailscale + key auth are verified.

## License

MIT (or project default). Treat secrets and private host details as confidential regardless of license.

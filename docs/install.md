# Install sequence

Target: **Ubuntu Server LTS** on an Intel NUC (or similar), prepared as an agent workspace.

## 0. Hardware

- Confirm firmware/BIOS is current enough for the Ubuntu release.
- Prefer UEFI + NVMe.
- Optional: enable firmware disk password / LUKS during install if the chassis is portable.

## 1. OS install

1. Flash Ubuntu Server LTS to USB (Balena Etcher, `dd`, etc.).
2. Install with:
   - OpenSSH server **enabled**
   - A non-root admin user with sudo
   - Optional: Docker snap **disabled** (we install Docker Engine via `just docker`)
3. Note the LAN IP from the installer or router.

## 2. First login (LAN)

From a trusted laptop:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub YOURUSER@NUC_LAN_IP
ssh YOURUSER@NUC_LAN_IP
```

Confirm sudo works: `sudo -v`.

## 3. Clone this repository

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/OWNER/agent-workspace.git ~/agent-workspace
cd ~/agent-workspace
```

Use SSH clone if you already have GitHub access from the NUC.

## 4. Bootstrap tooling

```bash
chmod +x scripts/*.sh
./scripts/bootstrap.sh
# or, once just is on PATH:
export PATH="$HOME/.local/bin:$PATH"
just bootstrap
```

Then:

```bash
just docker
just uv
just dotfiles
```

Log out/in (or `newgrp docker`) so the `docker` group applies.

## 5. Tailscale

```bash
just tailscale
```

Complete the browser auth. Confirm from the laptop:

```bash
tailscale status
ssh YOURUSER@$(tailscale ip -4)   # or Host entry from SSH config
```

## 6. Git identity (local only)

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
	name = Your Name
	email = you@example.com
EOF
```

## 7. SSH hardening (last)

Only after **key login works over Tailscale** and you still have console/LAN recovery:

```bash
AGENT_WORKSPACE_CONFIRM_SSH_HARDEN=yes just harden-ssh
```

Open a **second** SSH session to verify before closing the first.

## 8. Verify

```bash
just doctor
tmux new -s main
```

## 9. Optional Compose workloads

Copy `docker/compose.example.yml` to something under `local/` or a project dir and start stacks there. Keep production secrets out of git.

## Checklist

- [ ] Ubuntu Server LTS installed
- [ ] SSH key login works
- [ ] `just bootstrap` / docker / uv / dotfiles done
- [ ] Tailscale up
- [ ] `just harden-ssh` only after dual-path verify
- [ ] `just doctor` clean enough to work
- [ ] Named tmux session for long jobs

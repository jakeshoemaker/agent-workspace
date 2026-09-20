# Recovery notes

## Locked out of SSH (password disabled, key lost)

1. **Physical console** or IP-KVM / Intel AMT if configured.
2. Log in locally as the admin user.
3. Fix authorized keys:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'ssh-ed25519 AAAA... your-laptop' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

4. Or temporarily re-enable passwords (console only):

```bash
sudo rm -f /etc/ssh/sshd_config.d/60-agent-workspace-hardening.conf
sudo systemctl reload ssh || sudo systemctl reload sshd
```

Then restore key auth and re-run hardening.

## Tailscale broken

1. Console/LAN login.
2. Check service: `sudo systemctl status tailscaled`
3. Re-auth: `sudo tailscale up`
4. If the node was removed from the admin console, re-enroll as a new node and update laptop SSH `HostName`.

## Disk full

```bash
df -h
docker system df
# Only if you accept data loss of unused images:
# docker system prune -af
journalctl --disk-usage
sudo journalctl --vacuum-time=7d
```

## Bad dotfiles symlink

Install script leaves timestamped `*.bak.*` next to replaced files.

```bash
ls -la ~/.*bak* ~/.config/tmux/ 2>/dev/null
# restore example:
mv ~/.bashrc.bak.YYYYMMDDHHMMSS ~/.bashrc
```

Or re-run `just dotfiles` after fixing the repo.

## Rebuild from scratch

1. Back up `~/.ssh`, `secrets/`, and any project data (not only this repo).
2. Reinstall Ubuntu Server LTS.
3. Follow `docs/install.md`.
4. Restore secrets and SSH authorized_keys from backup.
5. Rejoin Tailscale; update ACLs if the node key changed.

## Kernel panic / won't boot

1. GRUB recovery / older kernel.
2. Live USB → mount root → chroot → fix packages.
3. Last resort: reinstall, restore data partitions if separate.

## Do not

- Do not wipe disks from an automated agent recipe.
- Do not commit recovery private keys into git "for convenience".
- Do not expose sshd to `0.0.0.0` on a public IP to bypass Tailscale without understanding the risk.

# Notes for agents working on this host / repo

## What this repo is

Tracked setup for an Ubuntu NUC agent workspace: plain dotfiles, bash scripts, `just`, Docker, Tailscale, tmux.

## Do

- Prefer `just` recipes and `scripts/*.sh` over ad-hoc system changes.
- Keep secrets out of git (`secrets/`, `.env`, keys).
- Run long work inside **tmux** (`just tmux-new` or `tmux new -s …`).
- Re-run `just doctor` after provisioning changes.
- Back up before replacing configs; install-dotfiles already creates `*.bak.*`.

## Do not

- Do not use chezmoi, mise, NixOS, or new dotfile managers without an explicit human decision.
- Do not run `harden-ssh` without `AGENT_WORKSPACE_CONFIRM_SSH_HARDEN=yes` and a recovery path.
- Do not push to the default branch as a shortcut; use PRs when the remote expects them.
- Do not store private keys, tokens, or customer data in tracked files.
- Do not add destructive disk wipe / `rm -rf /` automation.

## Layout reminder

| Path | Role |
| --- | --- |
| `dotfiles/` | Symlinked into `$HOME` |
| `scripts/` | Install and maintain |
| `secrets/`, `local/` | Untracked machine state |
| `docs/` | Install, security, recovery |

## SSH maintenance tip

Keep one live session open when reloading sshd. Test a second connection before disconnecting.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.

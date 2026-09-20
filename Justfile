# agent-workspace — common setup and maintenance
# Run `just` with no args to list recipes.
# Prefer these entrypoints over ad-hoc sudo; scripts are the source of truth.

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

repo := justfile_directory()

default:
	@just --list

# --- bootstrap ---

# Install baseline apt packages and core CLI tools (idempotent-ish).
bootstrap:
	{{repo}}/scripts/bootstrap.sh

# Install Docker Engine + Compose plugin; add $USER to docker group.
docker:
	{{repo}}/scripts/install-docker.sh

# Install Tailscale; print auth instructions (does not auto-approve).
tailscale:
	{{repo}}/scripts/install-tailscale.sh

# Install uv (Python package/runner) for the current user.
uv:
	{{repo}}/scripts/install-uv.sh

# Install just system-wide if missing (bootstrap usually covers this).
just-tool:
	{{repo}}/scripts/install-just.sh

# Symlink tracked dotfiles into $HOME (backs up existing paths first).
dotfiles:
	{{repo}}/scripts/install-dotfiles.sh

# SSH hardening via drop-in config. ONLY after key login + recovery path verified.
harden-ssh:
	{{repo}}/scripts/harden-ssh.sh

# Full first-boot path: packages → docker → uv → just → dotfiles.
# Tailscale and SSH harden are intentionally separate (interactive / risky).
setup: bootstrap docker uv just-tool dotfiles
	@echo
	@echo "Next (manual / interactive):"
	@echo "  just tailscale    # authenticate this host"
	@echo "  # verify: ssh over Tailscale works"
	@echo "  just harden-ssh   # only after key+tailscale verified"
	@echo "  just doctor"

# --- maintenance ---

# apt update/upgrade + refresh common tools.
update:
	{{repo}}/scripts/update.sh

# Print versions and quick health checks (no changes).
doctor:
	{{repo}}/scripts/doctor.sh

# --- tmux helpers ---

# Create or attach a named tmux session (default: main).
tmux-new name="main":
	tmux has-session -t "{{name}}" 2>/dev/null && tmux attach -t "{{name}}" || tmux new -s "{{name}}"

tmux-ls:
	tmux ls || echo "(no sessions)"

# --- docker helpers ---

# Validate example compose file (does not start stacks).
compose-check:
	docker compose -f {{repo}}/docker/compose.example.yml config

# --- safety ---

# Refuse destructive disk ops from recipes; document recovery instead.
# Agents: do not add `rm -rf /`, disk wipe, or force-push recipes here.
warn-destructive:
	@echo "No destructive disk recipes in this Justfile."
	@echo "See docs/recovery.md for rebuild / unlock procedures."

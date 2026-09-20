# ~/.bashrc — agent-workspace (symlinked from repo)
# Interactive non-login bash settings. Login shells also source this via .profile.

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac

# History
HISTCONTROL=ignoreboth
HISTSIZE=50000
HISTFILESIZE=100000
shopt -s histappend
shopt -s checkwinsize

# Less noise from macOS bash deprecation if ever sourced there
export BASH_SILENCE_DEPRECATION_WARNING=1

# PATH: user local bins first (uv, just, pip --user, etc.)
export PATH="${HOME}/.local/bin:${PATH}"

# Prompt: show user@host and cwd; mark git branch lightly if available
__aw_git_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/.*/(&)/'
}
PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]$(__aw_git_branch)\$ '

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias g='git'
alias ta='tmux attach || tmux new -s main'
alias tl='tmux ls'
alias tn='tmux new -s'

# Safer defaults
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# Editors
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

# uv / Python
if [[ -f "${HOME}/.local/bin/env" ]]; then
  # shellcheck disable=SC1091
  source "${HOME}/.local/bin/env"
fi

# Machine-local overrides (untracked)
if [[ -f "${HOME}/.bashrc.local" ]]; then
  # shellcheck disable=SC1091
  source "${HOME}/.bashrc.local"
fi

#!/usr/bin/env bash
# Regression check: doctor should tolerate harnesses that do not export USER.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
OUT="${TMP_HOME}/doctor.out"
trap 'rm -rf "${TMP_HOME}"' EXIT

HOME="${TMP_HOME}" "${ROOT}/scripts/install-dotfiles.sh" >/dev/null

set +e
env -u USER HOME="${TMP_HOME}" "${ROOT}/scripts/doctor.sh" >"${OUT}" 2>&1
status=$?
set -e

if grep -q 'USER: unbound variable' "${OUT}"; then
  cat "${OUT}" >&2
  echo "doctor failed before checks when USER was unset" >&2
  exit 1
fi

if ! grep -q '^summary:' "${OUT}"; then
  cat "${OUT}" >&2
  echo "doctor did not reach summary when USER was unset" >&2
  exit 1
fi

for expected in \
  '  [ok]   ~/.bashrc is symlink' \
  '  [ok]   tmux.conf present' \
  '  [ok]   ~/.ssh is 700'; do
  if ! grep -Fq "${expected}" "${OUT}"; then
    cat "${OUT}" >&2
    echo "missing expected doctor output: ${expected}" >&2
    exit 1
  fi
done

printf 'doctor USER-unset regression passed (doctor exit %s; host-dependent failures tolerated)\n' "${status}"

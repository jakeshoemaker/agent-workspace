# Remote agent readiness

This optional layer turns the baseline NUC into a supervised remote worker for a
Firstmate operator using Herdr for panes and Pi for child agents. Keep these
checks free of host-specific addresses, private keys, API tokens, and OAuth
credentials.

## Preconditions

- The baseline install in [`install.md`](install.md) is complete enough that the
  operator can SSH to the NUC over Tailscale using keys.
- Keep one known-good SSH session open while changing SSH or remote-agent
  routing.
- Treat these as explicit operator decisions:
  - which projects may route to the NUC;
  - which Pi provider/model the NUC account may use;
  - completing GitHub and Pi login on the NUC account itself.
- Do not copy private keys, browser cookies, OAuth files, API tokens, or provider
  credentials from another machine.

## Host checks on the NUC

Run these from the NUC account that will own remote work. They should print
versions or readiness only; do not use flags that print credentials.

```bash
node --version
pi --version
treehouse --version
tasks-axi --version
gh-axi --version
quota-axi --version
chrome-devtools-axi --version
lavish-axi --version
no-mistakes --version
herdr --version
herdr status
```

Acceptance:

- required commands resolve on the NUC account's runtime `PATH`;
- `herdr status` reports a running server for the intended session and says the
  client/server protocols are compatible;
- no command output is copied into an issue or PR if it contains a token, host
  address, or private path that should stay local.

## Network and SSH checks

Use service state and redacted Tailscale state instead of publishing addresses.

```bash
systemctl is-active ssh || systemctl is-active sshd
systemctl is-active tailscaled
tailscale status --json | jq -r '"BackendState=\(.BackendState) SelfOnline=\(.Self.Online)"'
```

Acceptance:

- SSH and `tailscaled` are active;
- Tailscale reports the node online;
- a second SSH connection over Tailscale succeeds before any SSH hardening or
  route cutover is considered complete.

Docker is useful for some workloads, but it is not required for Herdr/Pi remote
routing unless the project task itself needs containers.

## Pi and GitHub authentication

Complete authentication on the NUC account directly. Check readiness without
printing secrets:

```bash
pi auth check --provider PROVIDER --model MODEL --json --no-refresh
gh auth status
gh-axi repo view OWNER/REPO
```

Acceptance:

- the selected Pi provider/model reports `"status":"ready"`;
- GitHub reads work through both `gh` and `gh-axi`;
- no `--credentials`, token-printing, or private key output is captured.

## Firstmate remote-route check

From the Firstmate home that supervises the NUC, use the supported remote doctor
instead of ad-hoc process edits:

```bash
bin/fm-on.sh NUC_ALIAS fm-remote-doctor.sh
```

Acceptance:

- required tools are present in the remote runtime path;
- the remote job worker is running and fresh;
- the dedicated Herdr session for remote work is running and protocol-compatible;
- the report ends with remote second-mate readiness confirmed.

If the doctor reports a fixable gap, use its recommended repair path. If it
reports a human gap, stop and have the operator resolve the login, auth, or
machine access issue locally.

## Supervised-task smoke

Before routing real work, launch one bounded, low-risk task through the NUC
route. Good smoke tasks are documentation checks or a tiny repository fix with a
normal PR. The smoke is successful only when all of these are true:

- task metadata records `harness=pi`, `backend=herdr`, and the expected remote
  Herdr session;
- the worker can read the target repository and use GitHub tooling;
- the task finishes through the normal project delivery path (report, PR, or
  merge according to that task's mode);
- the outcome is recorded without exposing host addresses or credentials.

For issue tracking, include the PR/report URL and a short redacted readiness
summary. Do not include raw SSH config, Tailscale IPs, OAuth files, API keys, or
private key paths.

## Evidence template

Use a short record like this when updating a setup issue:

```text
Remote NUC readiness checked at YYYY-MM-DDTHH:MMZ on repo COMMIT.
Herdr: VERSION, protocol compatible, SESSION running.
Pi: PROVIDER/MODEL auth check ready without credential output.
Network: ssh and tailscaled active; Tailscale self online.
Firstmate route: remote doctor confirmed required tools, worker freshness, and
Herdr session readiness.
Smoke: supervised task completed at URL.
Remaining gaps: none / list smallest follow-up.
```

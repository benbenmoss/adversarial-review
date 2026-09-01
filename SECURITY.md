# Security Policy

## Supported Versions

Only the latest tagged release is supported. Update to the newest version
before reporting an issue.

## Reporting a Vulnerability

Do not open a public issue for security vulnerabilities.

Use [GitHub's private vulnerability reporting](https://github.com/benbenmoss/adversarial-review/security/advisories/new)
for this repo instead. Include:

- Affected version / commit
- Reproduction steps
- Impact (what an attacker gains)

Expect an initial response within a few days. This is a solo-maintained
project run outside working hours -- there's no SLA, but reports won't be
ignored.

## Scope

This plugin runs entirely locally (hooks + skill invoked by Claude Code) --
no network calls, no telemetry, no remote execution. Relevant vulnerability
classes: shell injection in `hooks/*.sh`, unsafe eval of repo content,
path traversal reading files outside the working tree.

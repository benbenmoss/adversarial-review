# adversarial-review

<p align="center"><em>Skeptical senior review of everything you've changed so far, run locally, automatically, fixes what actually matters.</em></p>

Not an MR/PR tool. No GitHub, no GitLab, no API calls. It reads `git diff` in your working tree and stops at commentary for nothing -- every critical finding gets patched in place.

## Install

**Claude Code**

```
/plugin marketplace add benbenmoss/adversarial-review
```
```
/plugin install adversarial-review@adversarial-review
```
(Two separate prompts -- the install needs the marketplace added first.)

## How it works

Two hooks watch your working tree for changes that haven't had a review pass yet -- both no-ops on a clean tree, and both no-ops if the current diff was already reviewed:

1. **On every prompt you send** (`UserPromptSubmit`) -- if there's an unreviewed diff, a reminder is injected alongside your new request telling Claude to review it first.
2. **On every task-list create/update** (`PostToolUse` on `TodoWrite`) -- same check, same reminder. Starting or updating a plan is exactly when accumulated changes are worth checking before moving to the next step.

Either trigger runs the same `adversarial-review` skill, which:

3. **Reviews** the *whole* accumulated diff (`git diff HEAD`) -- not just the latest edit, everything changed so far this session -- against a fixed, narrow scope (below).
4. **Remediates.** Every 🔴 High finding gets fixed in place with a real edit, not just flagged. 🟠 Medium gets fixed if the patch is small and safe, otherwise reported. 🟡 Low is reported only.
5. **Reports** findings in a fixed severity-bucketed format, ending in a one-line summary: safe to ship or not.

You can also invoke the skill directly any time, outside of the two automatic triggers.

## What it catches

- Logic regressions -- inverted conditions, off-by-one, dropped cases
- Breaking interface changes -- signature, return shape, error contract
- Unhandled error paths -- swallowed exceptions, missing checks at trust boundaries
- Concurrency/state bugs -- races, non-atomic read-modify-write, lock ordering
- Security holes -- injection, authz gaps, secrets, unsafe deserialization, SSRF

## What it ignores

- Naming, formatting, style
- Bikeshedding on code that already works
- Speculative abstractions ("this could be more generic")
- Anything the language or framework already guarantees

If a diff has nothing in scope wrong with it, the skill says so in one line. It does not manufacture findings to justify the pass.

## Requirements

`git`, `bash`, `cksum` (POSIX standard, ships everywhere). No other runtime, no network access.

## License

MIT

# adversarial-review

<p align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/benbenmoss/adversarial-review/validate.yml?style=flat-square&label=validate" alt="Validate status">
  <img src="https://img.shields.io/github/v/release/benbenmoss/adversarial-review?style=flat-square&color=111111&label=release" alt="Release">
  <img src="https://img.shields.io/github/license/benbenmoss/adversarial-review?style=flat-square&color=111111" alt="MIT license">
  <img src="https://img.shields.io/github/stars/benbenmoss/adversarial-review?style=flat-square&color=111111&label=stars" alt="Stars">
</p>

<p align="center"><em>Skeptical senior review of everything you've changed so far, run locally, automatically, fixes what actually matters.</em></p>

Not an MR/PR tool. No GitHub, no GitLab, no API calls. It reads your local working tree -- tracked diff and untracked new files both -- and every High-severity finding gets patched in place, not just described.

## Before / after

You ask for a feature. Claude ships it, the happy path works, and a shared counter gets incremented from two goroutines without a lock.

Without adversarial-review: that ships. Nobody notices until it's flaky in production.

With adversarial-review, before the next prompt is even acted on:

```
### High

**Race on the shared counter under concurrent requests**

`stats.count += 1` in `handler.go:88` is a non-atomic read-modify-write hit
from every request goroutine. Fixed: replaced with `atomic.AddInt64(&stats.count, 1)`.
```

Patched in place. No commentary-only review, no waiting for a human to catch it later.

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

Two hooks watch your working tree for changes that haven't had a review pass yet -- both no-ops on a clean tree, and both no-ops if the current diff was already reviewed within the last 15 minutes:

1. **On every prompt you send** (`UserPromptSubmit`) -- if there's an unreviewed diff, a reminder is injected alongside your new request telling Claude to review it first.
2. **On every task-list create/update** (`PostToolUse` on `TodoWrite`) -- same check, same reminder. Starting or updating a plan is exactly when accumulated changes are worth checking before moving to the next step.

These are nudges, not a hard gate -- a hook can inject a reminder into context but can't force a tool call. If one is ignored, the same unreviewed diff resurfaces on the next trigger rather than staying silent forever.

Either trigger runs the same `adversarial-review` skill, which:

3. **Reviews** the *whole* accumulated diff -- tracked changes and untracked new files, not just the latest edit, everything changed so far this session -- against a fixed, narrow scope (below). If a hunk changes a signature, return type, error contract, exported symbol, schema, or config key, it also greps the rest of the repo for callers that weren't updated to match.
4. **Remediates.** Before writing a fix it checks how the file/package already handles errors and logging, and matches that pattern. Every High finding gets fixed in place with a real edit, not just flagged (unless no safe mechanical fix exists, in which case it's reported with why). Medium gets fixed if the patch is small and safe, otherwise reported. Low is reported only.
5. **Reports** findings in a fixed severity-bucketed format, ending in a one-line summary: safe to ship or not. If it patched anything, it also rewrites its own reviewed-diff marker afterward, so the next prompt doesn't nudge again over the fix it just made.

You can also invoke the skill directly any time, outside of the two automatic triggers.

## End-to-end flow

1. Code in the working tree changes -- from Claude, from you editing by hand, from another agent, from a merge, doesn't matter. The skill only looks at working-tree state vs. `HEAD`, never who or what produced it.
2. A prompt goes in, or a todo list updates.
3. A hook hashes the current diff (tracked + untracked). New or stale hash -> it injects a reminder. Unchanged hash within 15 minutes -> silent, nothing to do.
4. Claude runs the `adversarial-review` skill: reads the whole diff, greps the repo for callers left broken by any changed signature, builds a severity-bucketed report.
5. High findings get patched immediately. Medium only if the fix is small and safe. Low is reported, never touched.
6. If anything was patched, the skill re-reviews the touched files, runs the project's build/test command if one exists, and writes its own post-fix hash to the marker.
7. Next prompt: hash matches -> no nudge, until you change something else.

## What it catches

- Logic regressions -- inverted conditions, off-by-one, dropped cases
- Breaking interface changes -- signature, return shape, error contract, including callers elsewhere in the repo the diff didn't touch
- Unhandled error paths -- swallowed exceptions, missing checks at trust boundaries
- Concurrency/state bugs -- races, non-atomic read-modify-write, lock ordering
- Security holes -- injection, authz gaps, secrets, unsafe deserialization, SSRF
- Resource lifecycle -- leaked handles/connections/goroutines, missing close/cancel/defer
- Idempotency -- side effects that duplicate on retry (reported, never auto-fixed -- needs a design call)
- Deploy-skew compatibility -- schema/API/config changes that break while old and new versions run at once, when the diff touches something a deployed service actually consumes (reported, never auto-fixed)

## What it ignores

- Naming, formatting, style
- Bikeshedding on code that already works
- Speculative abstractions ("this could be more generic")
- Anything the language or framework already guarantees

If a diff has nothing in scope wrong with it, the skill says so in one line. It does not manufacture findings to justify the pass.

## Requirements

`git`, `bash`, `cksum` (POSIX standard). Works out of the box on macOS/Linux; on Windows it needs Git Bash or WSL. No other runtime, no network access.

## License

MIT

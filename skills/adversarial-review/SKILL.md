---
name: adversarial-review
description: Use whenever there are local code changes not yet given a skeptical, senior-level pass -- triggered automatically on user-prompt-submit and on task-list creation/updates, or invoke directly any time. Reviews everything changed so far in the working tree (git diff HEAD), not just the last edit. Not tied to GitHub, GitLab, or any MR/PR workflow -- purely local. Produces a severity-bucketed findings report and applies fixes for every substantive issue directly, in place. Not for style nits, naming preferences, or speculative refactors -- those are explicitly out of scope.
version: 0.2.0
license: MIT
metadata:
  audience: developers
  workflow: local-diff
---

# Adversarial Review

Skeptical, reviewer-mode pass over the accumulated local diff -- everything changed so far, regardless of how many edits or turns it took to get there. Unlike a normal review, this skill doesn't stop at commentary: every valid High/Critical finding gets a real patch, applied before moving on.

Purely local. No dependency on GitHub, GitLab, or any MR/PR concept -- it reads `git diff`, nothing else.

## Scope

**In scope** -- the review hunts for:
- Critical logic regressions (wrong output, off-by-one, inverted conditions, dropped cases)
- Breaking interface changes (signature, return shape, error contract, public API)
- Unhandled error paths (swallowed exceptions, missing null/empty checks at trust boundaries, unchecked external calls)
- Concurrency/state issues (races, non-atomic read-modify-write, shared mutable state, lock ordering)
- Security vulnerabilities (injection, auth/authz gaps, secrets, unsafe deserialization, SSRF)

**Out of scope** -- never raise these, even as "low" findings:
- Naming preferences, formatting, style
- Bikeshedding on already-working code
- Speculative abstractions ("this could be more generic")
- Anything the language/framework already guarantees

If nothing in scope is wrong, say so in one line and stop -- don't manufacture findings to justify the pass.

## When this runs

- **Automatically**, via two hooks in this plugin: on every `UserPromptSubmit` (before your next request is acted on), and on every `PostToolUse` for `TodoWrite` (whenever a task list is created or updated). Both only fire if there's a diff that hasn't been reviewed yet -- a clean tree, or a diff already reviewed and unchanged since, triggers nothing.
- **Manually**, invoke this skill directly any time you want a pass over the current working tree.

Either way the review always covers the *whole* accumulated diff (`git diff HEAD`), not just whatever changed since the last nudge -- so a review triggered mid-task still catches everything done in earlier steps too.

## Workflow

1. Get the diff: `git diff HEAD` (falls back to `git diff --cached` if `HEAD` is empty, e.g. an initial commit). This is the full set of local changes so far, not just the latest edit. If the diff touches a function/class whose full context isn't in the hunk, read the surrounding file -- diffs lie by omission.
2. Review against [Scope](#scope) only. Trace each changed code path to a concrete failure scenario (specific input/state -> wrong output/crash) -- if you can't construct one, it's not a finding.
3. Report findings per [Output format](#output-format).
4. **Remediate.** For every 🔴 High finding: apply the fix directly with Edit, don't just describe it. For 🟠 Medium: fix it if the change is small and obviously safe; otherwise leave it as a finding for the author to triage. Never auto-fix 🟡 Low -- report only.
5. If you changed anything in step 4, re-run step 1-2 against the new diff for the files you touched, to confirm the fix didn't introduce a new instance of the same class of bug. Note in the report what was auto-fixed.

## Output format

```
## Adversarial Review

<One short framing paragraph: safe to ship as-is? main takeaway? 2-3 sentences.>

---

### 🔴 High

**<Short noun-phrase heading>**

<What, why, where (file:line), the failure scenario, and what was fixed -- or why it wasn't safe to auto-fix.>

---

### 🟠 Medium

...

---

### 🟡 Low / Nitpicks

...

---

**Summary:** <One sentence. Safe to ship? What's still outstanding, if anything.>
```

### Rules

- Severity buckets are fixed order: 🔴 High -> 🟠 Medium -> 🟡 Low / Nitpicks. Omit empty buckets -- absence is the signal, never write "no high-severity issues found."
- Each finding: bold noun-phrase heading + one body paragraph with a concrete failure scenario, not a vague concern.
- No `✅ What is done well` bucket here -- this is a gate, not a courtesy review; skip the praise.
- Always end with `**Summary:**`, one sentence.
- When in doubt between two severities, pick the lower one. Inflated severity trains you to ignore this skill.

### Severity

- **🔴 High** -- incorrect behavior, security hole, data loss, or a broken contract that ships if untouched. Always auto-fix.
- **🟠 Medium** -- real but not certain to bite (fragile pattern, missed edge case under unlikely conditions). Auto-fix only if the patch is small and unambiguous.
- **🟡 Low / Nitpicks** -- everything else that's still in scope but minor. Report, never auto-fix, never invent from out-of-scope categories.

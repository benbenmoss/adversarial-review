#!/usr/bin/env bash
# PostToolUse hook (matcher: TodoWrite). Firing a task list usually means
# a chunk of work just landed or is about to start -- if there's an
# unreviewed diff at that point, feed Claude a reminder to review it before
# moving on to the next task.
set -euo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

DIFF="$(git diff HEAD -- . 2>/dev/null || true)"
[ -z "$DIFF" ] && DIFF="$(git diff --cached 2>/dev/null || true)"
[ -z "$DIFF" ] && exit 0

HASH="$(printf '%s' "$DIFF" | cksum)"
MARKER="$(git rev-parse --git-dir 2>/dev/null)/adversarial-review.last"
PREV="$(cat "$MARKER" 2>/dev/null || true)"
[ "$HASH" = "$PREV" ] && exit 0
printf '%s' "$HASH" > "$MARKER"

cat <<JSON
{
  "decision": "block",
  "reason": "Task list created/updated with an unreviewed diff in the working tree. Run the adversarial-review skill against everything changed so far (git diff HEAD) before starting the next task. Apply concrete fixes for every High-severity finding directly."
}
JSON

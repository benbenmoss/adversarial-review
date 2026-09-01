#!/usr/bin/env bash
# PostToolUse hook (matcher: TodoWrite). Firing a task list usually means
# a chunk of work just landed or is about to start -- if there's an
# unreviewed diff at that point, feed Claude a reminder to review it before
# moving on to the next task.
#
# Dedup marker: content-hash + timestamp. If ignored, the same diff re-nags
# after TTL_SECONDS -- a hook can't verify the skill actually ran, so a
# permanent one-shot marker would silence a diff forever on one dropped nudge.
set -euo pipefail

TTL_SECONDS=900

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

STATUS="$(git status --porcelain=v1 2>/dev/null || true)"
[ -z "$STATUS" ] && exit 0

TRACKED="$(git diff HEAD 2>/dev/null || true)"
[ -z "$TRACKED" ] && TRACKED="$(git diff --cached 2>/dev/null || true)"
UNTRACKED_FILES="$(git ls-files -z --others --exclude-standard 2>/dev/null || true)"
UNTRACKED=""
[ -n "$UNTRACKED_FILES" ] && UNTRACKED="$(printf '%s' "$UNTRACKED_FILES" | xargs -0 cat -- 2>/dev/null || true)"
HASH="$(printf '%s\x00%s' "$TRACKED" "$UNTRACKED" | cksum)"

MARKER="$(git rev-parse --git-dir 2>/dev/null)/adversarial-review.last"
NOW="$(date +%s)"
if [ -f "$MARKER" ]; then
  PREV_HASH="$(sed -n '1p' "$MARKER" 2>/dev/null || true)"
  PREV_TIME="$(sed -n '2p' "$MARKER" 2>/dev/null || true)"
  if [ "$HASH" = "$PREV_HASH" ] && [ -n "${PREV_TIME:-}" ] && [ $(( NOW - PREV_TIME )) -lt "$TTL_SECONDS" ]; then
    exit 0
  fi
fi
printf '%s\n%s\n' "$HASH" "$NOW" > "$MARKER"

cat <<JSON
{
  "decision": "block",
  "reason": "Task list created/updated with an unreviewed diff in the working tree -- including any untracked new files (git status shows ??), which don't show up in git diff. Run the adversarial-review skill against everything changed so far before starting the next task. Apply concrete fixes for every High-severity finding directly."
}
JSON

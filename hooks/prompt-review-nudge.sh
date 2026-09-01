#!/usr/bin/env bash
# UserPromptSubmit hook: if the working tree has code changes that haven't
# been through an adversarial-review pass yet, inject a reminder alongside
# the user's new prompt. Non-blocking -- the prompt still goes through.
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

cat <<'EOF2'
There are code changes in this working tree not yet covered by an adversarial-review pass. Before acting on this new request: run the adversarial-review skill against the accumulated diff (git diff HEAD), covering everything changed so far in this session -- not just the latest edit. Apply concrete fixes for every High-severity finding directly.
EOF2

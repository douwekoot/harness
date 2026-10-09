#!/usr/bin/env bash
# PostToolUse on edits: mark the work dirty and run the fast check.
# Exit 2 shows the failure output to Claude (the edit already happened).
. "$(dirname "$0")/common.sh"
[ "$HARNESS_ENABLED" = "1" ] || exit 0
cat >/dev/null  # consume hook input

ensure_state_dir
touch "$STATE_DIR/dirty"

detect_commands
[ -z "$HARNESS_CHECK" ] && exit 0

cd "$PROJECT_DIR" || exit 0
OUT="$(bash -c "$HARNESS_CHECK" 2>&1)"
STATUS=$?
if [ $STATUS -ne 0 ]; then
  {
    echo "harness sensor: '$HARNESS_CHECK' failed (exit $STATUS). Fix this before moving on."
    echo "----- last 40 lines -----"
    printf '%s\n' "$OUT" | tail -n 40
  } >&2
  exit 2
fi
exit 0

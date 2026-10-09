#!/usr/bin/env bash
# SessionStart: tell Claude which sensors are active and load the active contract.
# Plain stdout from SessionStart is added to Claude's context.
. "$(dirname "$0")/common.sh"
cat >/dev/null
[ "$HARNESS_ENABLED" = "1" ] || exit 0

detect_commands
echo "Project harness is active."
echo "- After each edit the harness runs: ${HARNESS_CHECK:-nothing (no check command found)}"
echo "- Before you can finish, it runs: ${HARNESS_TEST:-nothing (no test command found)}${HARNESS_CHECK:+ plus the check}"
echo "- Destructive git and rm commands and edits to .env or key files are blocked."
if [ -z "$HARNESS_CHECK$HARNESS_TEST" ]; then
  echo "- No commands detected. The user can run /harness:init to configure them."
fi
if [ -f "$STATE_DIR/task.md" ]; then
  echo
  echo "Active task contract (.claude/.harness/task.md). Work against it and stop when its acceptance criteria pass:"
  head -c 4000 "$STATE_DIR/task.md"
fi
exit 0

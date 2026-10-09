#!/usr/bin/env bash
# Stop: Claude may only finish when the test command passes.
# Runs only if files were edited since the last green run.
# After HARNESS_MAX_ATTEMPTS failed blocks it lets Claude stop and tells you.
. "$(dirname "$0")/common.sh"
[ "$HARNESS_ENABLED" = "1" ] || exit 0
cat >/dev/null

[ -f "$STATE_DIR/dirty" ] || exit 0

detect_commands
COUNT_FILE="$STATE_DIR/attempts"

if [ -z "$HARNESS_TEST" ] && [ -z "$HARNESS_CHECK" ]; then
  rm -f "$STATE_DIR/dirty"
  exit 0
fi

CMD="$HARNESS_TEST"
[ -n "$HARNESS_CHECK" ] && CMD="${HARNESS_CHECK}${CMD:+ && $CMD}"

cd "$PROJECT_DIR" || exit 0
OUT="$(bash -c "$CMD" 2>&1)"
STATUS=$?

if [ $STATUS -eq 0 ]; then
  rm -f "$STATE_DIR/dirty" "$COUNT_FILE" "$STATE_DIR/last-failure.log"
  exit 0
fi

N=$(( $(cat "$COUNT_FILE" 2>/dev/null || echo 0) + 1 ))
echo "$N" > "$COUNT_FILE"

if [ "$N" -gt "$HARNESS_MAX_ATTEMPTS" ]; then
  rm -f "$COUNT_FILE" "$STATE_DIR/dirty"
  printf '%s\n' "$OUT" | tail -n 60 > "$STATE_DIR/last-failure.log"
  MSG="harness: checks still failing after $HARNESS_MAX_ATTEMPTS attempts. Claude was allowed to stop. Log: .claude/.harness/last-failure.log"
  printf '{"systemMessage":"%s"}\n' "$(json_escape "$MSG")"
  exit 0
fi

{
  echo "harness gate: you are not done. '$CMD' failed (exit $STATUS), attempt $N of $HARNESS_MAX_ATTEMPTS."
  echo "Fix the cause. Do not skip, delete or weaken tests. If you cannot fix it, stop editing, show the error and propose a fix to the user."
  echo "----- last 40 lines -----"
  printf '%s\n' "$OUT" | tail -n 40
} >&2
exit 2

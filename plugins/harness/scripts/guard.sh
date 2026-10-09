#!/usr/bin/env bash
# PreToolUse: mechanical gate for destructive commands and protected files.
# Exit 2 blocks the tool call and shows stderr to Claude.
. "$(dirname "$0")/common.sh"
[ "$HARNESS_ENABLED" = "1" ] || exit 0

INPUT="$(cat)"
TOOL="$(json_field "$INPUT" tool_name)"

block() {
  echo "harness guard: $1" >&2
  echo "This is a hard rule from the project harness. Do not retry it another way. If it is truly needed, stop and ask the user to run it." >&2
  exit 2
}

if [ "$TOOL" = "Bash" ]; then
  CMD="$(json_field "$INPUT" command)"
  CMD_FLAT="$(printf '%s' "$CMD" | tr -s ' ')"

  # rm -rf aimed at root, home, the whole project or a glob
  if printf '%s' "$CMD_FLAT" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*|-[a-zA-Z]*[fF][a-zA-Z]*[rR][a-zA-Z]*|-r[[:space:]]+-f|-f[[:space:]]+-r)[[:space:]]+(/|~|\$HOME|\*|\.|\.\.|\./?\*)([[:space:]]|$|;|&)'; then
    block "recursive delete of /, ~, ., .. or * is not allowed."
  fi
  printf '%s' "$CMD_FLAT" | grep -Eq 'git[[:space:]]+push([^;&|]*)[[:space:]](--force|-f)([[:space:]=]|$)' \
    && ! printf '%s' "$CMD_FLAT" | grep -q -- '--force-with-lease' \
    && block "force push is not allowed."
  printf '%s' "$CMD_FLAT" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' \
    && block "git reset --hard discards work and is not allowed."
  printf '%s' "$CMD_FLAT" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' \
    && block "git clean -f deletes untracked files and is not allowed."
  printf '%s' "$CMD_FLAT" | grep -Eq 'git[[:space:]]+(commit|push)[^;&|]*--no-verify' \
    && block "--no-verify skips the project's checks and is not allowed."
  # Deleting test files through the shell
  RM_ARGS="$(printf '%s' "$CMD_FLAT" | grep -Eo '(^|[;&|[:space:]])(rm|git[[:space:]]+rm)[[:space:]][^;&|]*' || true)"
  if [ -n "$RM_ARGS" ] && printf '%s' "$RM_ARGS" | grep -Eq '(^|[/[:space:]])(tests?|__tests__|spec)(/|[[:space:]]|$)|\.(test|spec)\.[A-Za-z]+|(^|[/[:space:]])test_[^[:space:]]*\.py|_test\.(go|py)'; then
    block "deleting test files is not allowed. Fix the code, not the tests."
  fi
  exit 0
fi

# File tools: protect secrets and git internals
FILE="$(json_field "$INPUT" file_path)"
[ -z "$FILE" ] && FILE="$(json_field "$INPUT" notebook_path)"
FILE_N="${FILE//\\\\//}"
FILE_N="${FILE_N//\\//}"
BASE="${FILE_N##*/}"

case "$BASE" in
  .env|.env.*)
    case "$BASE" in
      .env.example|.env.sample|.env.template) ;;
      *) block "editing $BASE is not allowed. Secrets files are off limits." ;;
    esac ;;
  *.pem|*.key|id_rsa|id_ed25519)
    block "editing key material ($BASE) is not allowed." ;;
esac
case "$FILE_N" in
  */.git/*) block "editing files inside .git is not allowed." ;;
esac
exit 0

#!/usr/bin/env bash
# Shared helpers for harness hooks. Sourced by the other scripts.
# No jq, no python: plain bash so it runs under Git Bash on Windows too.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
PROJECT_DIR="${PROJECT_DIR//\\//}"   # C:\proj -> C:/proj for Git Bash on Windows
STATE_DIR="$PROJECT_DIR/.claude/.harness"
CONFIG_FILE="$PROJECT_DIR/.claude/harness.env"

# Defaults. Override any of these in .claude/harness.env
HARNESS_CHECK=""        # fast check after each edit (lint/typecheck)
HARNESS_TEST=""         # full check before Claude may finish (tests)
HARNESS_MAX_ATTEMPTS=3  # times the Stop gate blocks before escalating to you
HARNESS_ENABLED=1       # set to 0 to switch the kit off for one project

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

have() { command -v "$1" >/dev/null 2>&1; }

# Value of "field": "value" in a JSON string, first match. Good enough for hook input.
json_field() {
  # sed -E (not \| in a basic regex) so it behaves the same on GNU, macOS/BSD and busybox sed.
  printf '%s' "$1" | tr -d '\n' | sed -nE "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\1/p" | head -n 1
}

pkg_has_script() {
  [ -f "$PROJECT_DIR/package.json" ] && grep -Eq "\"$1\"[[:space:]]*:" "$PROJECT_DIR/package.json"
}

pkg_runner() {
  if [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then echo "pnpm"
  elif [ -f "$PROJECT_DIR/yarn.lock" ]; then echo "yarn"
  elif [ -f "$PROJECT_DIR/bun.lockb" ] || [ -f "$PROJECT_DIR/bun.lock" ]; then echo "bun"
  else echo "npm"; fi
}

make_has_target() {
  [ -f "$PROJECT_DIR/Makefile" ] && grep -Eq "^$1:" "$PROJECT_DIR/Makefile"
}

# Fill HARNESS_CHECK / HARNESS_TEST from the project layout when not configured.
detect_commands() {
  local run
  local -a checks
  checks=()
  if [ -z "$HARNESS_CHECK" ] || [ -z "$HARNESS_TEST" ]; then
    if [ -f "$PROJECT_DIR/package.json" ]; then
      run="$(pkg_runner)"
      pkg_has_script lint && checks+=("$run run lint")
      pkg_has_script typecheck && checks+=("$run run typecheck")
      if [ -z "$HARNESS_TEST" ] && pkg_has_script test \
         && ! grep -q 'no test specified' "$PROJECT_DIR/package.json"; then
        HARNESS_TEST="$run test"
      fi
    elif [ -f "$PROJECT_DIR/Cargo.toml" ]; then
      checks+=("cargo check -q")
      [ -z "$HARNESS_TEST" ] && HARNESS_TEST="cargo test -q"
    elif [ -f "$PROJECT_DIR/go.mod" ]; then
      checks+=("go vet ./...")
      [ -z "$HARNESS_TEST" ] && HARNESS_TEST="go test ./..."
    elif [ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/requirements.txt" ] \
         || [ -f "$PROJECT_DIR/setup.py" ]; then
      have ruff && checks+=("ruff check .")
      if [ -z "$HARNESS_TEST" ] && { [ -d "$PROJECT_DIR/tests" ] || [ -d "$PROJECT_DIR/test" ]; }; then
        if have pytest; then HARNESS_TEST="pytest -q"
        elif have python3; then HARNESS_TEST="python3 -m pytest -q"
        elif have python; then HARNESS_TEST="python -m pytest -q"; fi
      fi
    elif [ -f "$PROJECT_DIR/Makefile" ]; then
      make_has_target lint && checks+=("make lint")
      [ -z "$HARNESS_TEST" ] && make_has_target test && HARNESS_TEST="make test"
    fi
    if [ -z "$HARNESS_CHECK" ] && [ "${#checks[@]}" -gt 0 ]; then
      HARNESS_CHECK="$(printf '%s && ' "${checks[@]}")"
      HARNESS_CHECK="${HARNESS_CHECK% && }"
    fi
  fi
}

# Escape a string for a JSON value.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

ensure_state_dir() { mkdir -p "$STATE_DIR" 2>/dev/null; }

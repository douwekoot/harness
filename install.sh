#!/usr/bin/env bash
# Installs the harness plugin for your user (all projects). Run from anywhere.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
command -v claude >/dev/null || { echo "claude CLI not found on PATH"; exit 1; }
chmod +x "$DIR"/plugins/harness/scripts/*.sh
claude plugin marketplace add "$DIR"
claude plugin install harness@harness
echo
echo "Done. Start Claude Code in a project and run /harness:init"
echo "Keep this folder where it is: Claude Code reads the plugin from it."

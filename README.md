Claude Code plugin that keeps software tasks on track:

- runs a quick check after edits and tests before Claude finishes;
- blocks common destructive commands;
- records task contracts and reviews the final diff.

## Install

Requires Claude Code and Bash. Windows users need [Git for Windows](https://git-scm.com/download/win).

### From GitHub

```bash
claude plugin marketplace add douwekoot/harness
claude plugin install harness@harness
```

### From a local copy

Keep the folder in a permanent location, then run the installer:

```bash
# Linux / macOS
bash install.sh
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The plugin is installed for your user and is available in every project. Restart Claude Code after installing.

## Use

Run these commands in a project:

```text
/harness:init
/harness:contract <task>
/harness:review
```

`/harness:init` detects the project’s checks and creates the local harness configuration. Use `/harness:contract` for non-trivial work. `/harness:review` asks a separate reviewer to check the diff against that contract.

The hooks then run automatically:

- **Session start:** loads the active contract and enabled checks.
- **Before commands and edits:** blocks risky operations.
- **After edits:** runs the fast check.
- **Before finishing:** runs the check and test commands.

For multi-file changes, ask Claude to use the `harness:planner` subagent first.

## Configure

Override the detected commands in `.claude/harness.env`:

```bash
HARNESS_CHECK="npm run lint && npm run typecheck"
HARNESS_TEST="npm test"
HARNESS_MAX_ATTEMPTS=3
HARNESS_ENABLED=1
```

If the existing test suite is already failing, fix it first or set `HARNESS_TEST=""`. The guard is pattern-based protection, not a sandbox, and hooks only see edits made through Claude’s file tools.

## Manage

```bash
claude plugin disable harness
claude plugin marketplace update harness
claude plugin marketplace remove harness
```

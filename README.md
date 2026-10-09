Claude Code plugin that implements the "harness engineering" setup: sensors after every edit, a gate that stops Claude from finishing while tests fail, a guard against destructive commands, task contracts and an adversarial reviewer.

## Requirements

- Claude Code (`claude` on your PATH)
- Bash. Linux and macOS have it. On Windows, install Git for Windows (Git Bash). Claude Code runs the hooks with it.

## Install

Compatible across Linux, macOS & Windows. Run installation in a terminal.

**Option A: GitHub**

```
claude plugin marketplace add douwekoot/harness
claude plugin install harness@harness
```

**Option B: Local**
    
Clone or unzip the kit somewhere permanent; don't move or delete the folder afterwards.

```bash
# Linux / macOS
cd ~/tools/harness
bash install.sh
```

```powershell
# Windows (PowerShell)
cd $HOME\tools\harness
powershell -ExecutionPolicy Bypass -File .\install.ps1
```
```manual
claude plugin marketplace add <path-to-folder>
claude plugin install harness@harness
```

Harness is installed at user scope, so it's active in every project. Restart any running Claude Code session, then check with `claude plugin list`.

## Use

In a project:

1. `/harness:init` once. Claude detects your lint and test commands, writes `CLAUDE.md` (boundaries, project map, verification, escalation), `.claude/harness.env`, permission deny rules in `.claude/settings.json`, and gitignores `.claude/.harness/`.
2. `/harness:contract <task>` before a non-trivial task. Writes the deliverable, constraints, non-goals and acceptance criteria to `.claude/.harness/task.md`. Every new session loads it.
3. Work normally. The hooks run on their own.
4. `/harness:review` before you accept the work. A separate reviewer subagent checks the diff against the contract.

The `harness:planner` subagent writes a blueprint before multi-file changes. Ask for it ("use the planner first").

## What runs automatically

| When | Script | Effect |
|---|---|---|
| Session start | `session-start.sh` | Tells Claude which checks are active and loads the active contract |
| Before Bash or a file edit | `guard.sh` | Blocks `rm -rf` on `/ ~ . .. *`, force push, `git reset --hard`, `git clean -f`, `--no-verify`, deleting test files, and edits to `.env`, key files and `.git/` |
| After a file edit | `check.sh` | Runs the fast check (lint or typecheck). On failure Claude sees the last 40 lines |
| When Claude tries to finish | `gate.sh` | If files were edited, runs check + tests. On failure Claude must keep working. After 3 failed attempts it lets Claude stop and shows you a message, with the log in `.claude/.harness/last-failure.log` |

Commands are detected automatically for npm/pnpm/yarn/bun (`lint`, `typecheck`, `test` scripts), Cargo, Go, Python (ruff, pytest) and Makefiles (`lint`, `test` targets). Without `/harness:init` the kit still works using this detection.

## Configure per project

`.claude/harness.env`:

```bash
HARNESS_CHECK="npm run lint && npm run typecheck"  # after each edit, keep it fast
HARNESS_TEST="npm test"                            # before finishing
HARNESS_MAX_ATTEMPTS=3                             # gate blocks before escalating
HARNESS_ENABLED=1                                  # 0 switches the kit off here
```

## Things to know

- The gate runs your whole test suite. If tests already fail before you start, Claude will try to fix them, even for an unrelated task. Get the suite green first, or set `HARNESS_TEST=""` for that project.
- A slow test suite makes every finished turn slow. Point `HARNESS_TEST` at a faster subset if needed.
- The guard is pattern matching, not a sandbox. The deny rules from `/harness:init` are the harder layer. Claude Code's docs recommend permission rules over hooks for hard enforcement.
- Hooks only see edits made through Claude's file tools. Files changed by a Bash command don't trigger the check.

## Update, disable, remove

- Edits to files in this folder apply at the next session start, or run `/reload-plugins`.
- Disable: `claude plugin disable harness`
- Remove: `claude plugin marketplace remove harness` (also uninstalls the plugin)
- Update (Option A): `claude plugin marketplace update harness`, then restart Claude Code

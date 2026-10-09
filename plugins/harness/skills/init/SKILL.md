---
name: init
description: Set up the harness in the current project. Writes the CLAUDE.md operating contract and project map, the harness config with check and test commands, and permission deny rules.
disable-model-invocation: true
---

Set up the project harness in the current project. Work through these steps in order and show the user what you changed at the end.

## 1. Detect commands

Look at the project files (package.json scripts, pyproject.toml, Cargo.toml, go.mod, Makefile, CI config in .github/workflows) and decide:
- CHECK: a fast command for after each edit (lint and/or typecheck). Should finish in under a minute. Leave empty if none exists.
- TEST: the full test command. Leave empty if there are no tests.

Run each command once to confirm it works. If one fails because of existing problems in the code, tell the user and still record it.

## 2. Write `.claude/harness.env`

```
HARNESS_CHECK="<check command>"
HARNESS_TEST="<test command>"
HARNESS_MAX_ATTEMPTS=3
HARNESS_ENABLED=1
```

## 3. Write or update `CLAUDE.md` at the project root

If CLAUDE.md exists, keep its content and add only the missing sections. Keep the whole file short. Use this structure:

```markdown
# Project operating contract

## Boundaries
- Change only files the current task needs. List anything else you want to touch and ask first.
- Never delete or weaken tests to make them pass.
- Never add a dependency without asking.
- Never read or edit .env files or key material.

## Project map
- <dir or file>: <one line on what lives there>
(only the 5 to 15 entries that matter; point to docs instead of copying them)

## Verification
- After edits the harness runs: <CHECK>
- Before finishing the harness runs: <TEST>
- A task is done only when these pass and the acceptance criteria in .claude/.harness/task.md are met.

## Failure escalation
- If the same check fails twice on the same error, stop editing, show the error and propose a fix. Wait for the user.

## Decisions
- See docs/decisions.md. Add a dated line there for every architectural choice the user accepts.
```

Build the project map from the real directory layout. Create `docs/decisions.md` with a heading if it does not exist.

## 4. Add permission deny rules

Edit `.claude/settings.json` (create it if missing, keep existing keys). Merge these into `permissions.deny` without duplicates:

```json
["Read(./.env)", "Read(./.env.*)", "Read(./**/*.pem)", "Read(./**/*.key)", "Bash(git push --force *)", "Bash(git reset --hard *)"]
```

## 5. Keep harness state out of git

If the project is a git repo, add `.claude/.harness/` to `.gitignore`.

## 6. Report

List the files you created or changed and the CHECK and TEST commands. Tell the user to restart Claude Code (or run /clear) so the session start message picks up the new config.

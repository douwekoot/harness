---
name: contract
description: Turn a request into a bounded task contract (deliverable, constraints, non-goals, acceptance criteria) saved to .claude/.harness/task.md. Use before starting any non-trivial task.
argument-hint: <task description>
---

Turn this request into a task contract: $ARGUMENTS

1. Read CLAUDE.md and look at the relevant files so the contract names real paths.
2. If something essential is ambiguous (what "done" means, which files are in scope), ask the user up to 3 short questions first. Otherwise make reasonable choices and list them under Assumptions.
3. Write `.claude/.harness/task.md`:

```markdown
# Task: <one line>

## Deliverable
- <exact files and their format or behavior>

## Constraints
- <allowed dependencies, style rules, performance or size limits>

## Non-goals
- <what must not be touched or added>

## Acceptance criteria
- [ ] <checkable condition, with the command that proves it>
- [ ] Harness check and test commands pass

## Assumptions
- <choices made without asking>
```

Every acceptance criterion must be checkable by running a command or reading a specific file. Replace vague wording like "works well" with something testable.

4. Show the contract to the user and ask them to confirm or edit it before you start. Do not start implementing in this step.

When the task is finished and reviewed, delete `.claude/.harness/task.md` or ask the user whether to keep it.

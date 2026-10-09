---
name: review
description: Run the adversarial review pass on the current changes with the reviewer subagent, then fix what it finds.
---

1. Delegate to the `harness:reviewer` subagent. Tell it which task is being reviewed and point it to `.claude/.harness/task.md` if it exists. Do not pass it your own opinion of the work.
2. Show the user the reviewer's verdict and findings as returned.
3. If the verdict is FAIL, fix each finding, then run the reviewer once more.
4. If it still fails after the second review, stop and list what is left for the user to decide.

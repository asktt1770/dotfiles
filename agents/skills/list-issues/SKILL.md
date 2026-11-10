---
name: list-issues
description: Lists the user's open GitHub issues by who acts next, priority, and days untouched. Use for `/list-issues`, or when the user asks which issue to do or hand off next ("次のissue出して").
---

# List Issues

Read only. Run this skill's `scripts/list-issues.nu` by its full path without changing directory, because the script takes the repository from the working directory. Add `--all` when the user asks about every repository, and show its output unchanged.

Then give one line to paste for the first `agent:ready` issue, using its reference exactly as listed, and start nothing yourself, because choosing is the user's step:

```text
/goal Issue owner/repo#60: finish Next action and meet Done when, or stop as Stop if says
```

The queue format and how each label runs are in the `create-issue` skill and the global Issue Queue rules.

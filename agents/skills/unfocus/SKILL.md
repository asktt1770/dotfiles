---
name: unfocus
description: Clears the main-task marker the `focus` skill set on the current cmux workspace (pin, colour, goal description) and closes this session's own tab. Use for `/unfocus` or when the user says the goal is done or dropped.
---

# Unfocus

Undo what the `focus` skill applied to the caller's cmux workspace, then end
this session. Outside cmux (`$CMUX_WORKSPACE_ID` unset), say there is nothing to
clear and stop.

Run one command, with nothing before it — no checks for uncommitted changes or
running tasks; the user handles those:

```bash
claude-focus clear --close
```

It unpins, clears the colour and removes only the `ゴール:` line, keeping the
user's own lines below it (a description without that line is left alone). It
verifies the result, then closes the tab this session runs in. Only that tab
closes; other tabs in the workspace, and the workspace itself, stay.

Since the tab closes, there is no report afterwards. If the command fails, the
tab stays open: report the error in one line.

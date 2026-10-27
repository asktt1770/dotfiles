---
name: unfocus
description: Clears the main-task marker the `focus` skill set on the current cmux workspace (pin, colour, goal description), which also stops the derailment guard. Use for `/unfocus` or when the user says the goal is done or dropped.
---

# Unfocus

Undo what the `focus` skill applied to the caller's cmux workspace. Outside cmux
(`$CMUX_WORKSPACE_ID` unset), say there is nothing to clear and stop.

1. Clear the marker in one call:

   ```bash
   claude-focus clear
   ```

   It unpins, clears the colour and removes only the `ゴール:` line, writing the
   user's own lines below it back. It then reads the workspace back, fails if
   anything did not take, and prints the result with `cleared_goal`.

   If it refuses because the description does not start with `ゴール:`, focus
   did not set it and it may be the user's own note. Ask before clearing, and
   rerun with `--force` only if they agree; that clears the whole description.

   The `UserPromptSubmit` hook reads the description on every prompt, so
   clearing it stops the guard immediately.

2. Report the cleared goal in one line. Leave `cmux todo` untouched — it belongs
   to the user.

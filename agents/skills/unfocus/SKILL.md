---
name: unfocus
description: Clears the main-task marker the `focus` skill set on the current cmux workspace (pin, colour, goal description). Use for `/unfocus` or when the user says the goal is done or dropped.
---

# Unfocus

Undo what the `focus` skill applied to the caller's cmux workspace. Outside cmux
(`$CMUX_WORKSPACE_ID` unset), say there is nothing to clear and stop.

1. Run one command:

   ```bash
   claude-focus clear
   ```

   It unpins, clears the colour and removes only the `ゴール:` line, keeping the
   user's own lines below it (a description without that line is left alone),
   then verifies the result. If it fails, report the error in one line and stop.

2. Reply with one line naming the cleared goal and ending with the `/exit`
   prompt, for example:

   ```text
   ゴール「PR #55 をマージ可能にする」を外しました。/exit で終了してください
   ```

   Do not end the session yourself.

---
name: unfocus
description: Clears the main-task marker the `focus` skill set on the current cmux workspace (pin, colour, goal description), which also stops the derailment guard. Use for `/unfocus` or when the user says the goal is done or dropped.
---

# Unfocus

Undo what the `focus` skill applied to the caller's cmux workspace. Outside cmux
(`$CMUX_WORKSPACE_ID` unset), say there is nothing to clear and stop.

1. Read the current description. `cmux identify --json` gives the caller's
   `window_ref` and `workspace_ref`; `workspace list` only covers one window, so
   scope it to the caller's:

   ```bash
   cmux identify --json | jq -c .caller
   cmux workspace list --json --window window:1 | jq '.workspaces[] | select(.ref == "workspace:3") | .description'
   ```

   If it does not start with `ゴール:`, focus did not set it — ask before
   clearing, since it may be the user's own note.

2. Clear the marker:

   ```bash
   cmux workspace-action --action unpin
   cmux workspace-action --action clear-color
   cmux workspace-action --action clear-description
   ```

   The `UserPromptSubmit` hook reads the description on every prompt, so
   clearing it stops the guard immediately.

3. Report the goal that was cleared in one line. Leave `cmux todo` untouched —
   it belongs to the user.

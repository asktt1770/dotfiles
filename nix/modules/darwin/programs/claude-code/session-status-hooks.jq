# Input: the live settings.json, then an object of hook entries per event.
.[0] as $settings
| .[1] as $ours
| $settings
| .hooks = (($settings.hooks // {}) + (
    $ours
    | with_entries(
        .key as $event
        # Keep other tools' hooks for this event, and drop this tool's commands
        # because they may name an older store path. A group is dropped only
        # when nothing else is left in it.
        | .value = ((($settings.hooks[$event] // [])
            | map(.hooks |= map(select((.command // "") | contains("claude-session-status") | not)))
            | map(select(.hooks | length > 0)))
          + .value)
      )
  ))

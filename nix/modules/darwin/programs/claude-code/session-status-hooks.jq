# Input: the live settings.json, then an object of hook entries per event.
.[0] as $settings
| .[1] as $ours
| $settings
| .hooks = (($settings.hooks // {}) + (
    $ours
    | with_entries(
        .key as $event
        # Keep other tools' hooks for this event, and drop this tool's entries
        # because they may name an older store path.
        | .value = ((($settings.hooks[$event] // [])
            | map(select(any(.hooks[]?; (.command // "") | contains("claude-session-status")) | not)))
          + .value)
      )
  ))

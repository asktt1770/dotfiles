# claude-focus: reads, applies and clears the main-task marker of the caller's
# cmux workspace for the `focus` and `unfocus` skills.
#
# Each subcommand does its whole job in one call — read the description, write
# the marker, read it back and verify — so a skill run costs one agent turn
# instead of several. Every subcommand prints one JSON record on success and
# fails with an actionable error otherwise.

# Marks the goal line, so `clear` removes only what `set` wrote.
const GOAL_PREFIX = 'ゴール:'

# Eisenhower quadrant → marker. Hex rather than cmux's named colours: the
# named Amber is a dark ochre that does not read as yellow in the sidebar, and
# Charcoal is darker than the intended grey.
const QUADRANTS = {
    DO: {color: '#E74C3C', pin: true}
    PLAN: {color: '#2ECC71', pin: false}
    DELEGATE: {color: '#F1C40F', pin: false}
    DROP: {color: '#95A5A6', pin: false}
}

# Run cmux and fail loudly with its stderr. The arguments come as a list
# because a rest parameter would parse cmux's own flags as this command's.
def cmux-run [args: list<string>]: nothing -> string {
    let result = ^cmux ...$args | complete
    if $result.exit_code != 0 {
        error make {msg: $"cmux ($args | str join ' ') failed: ($result.stderr | str trim)"}
    }
    $result.stdout
}

# The caller's window, workspace and surface refs. Every later command targets
# them explicitly, so the verification reads the same workspace the writes hit
# and `clear --close` can only ever close the caller's own tab.
def caller []: nothing -> record {
    if ($env.CMUX_WORKSPACE_ID? | is-empty) {
        error make {msg: 'Not inside cmux ($CMUX_WORKSPACE_ID is unset): there is no workspace to mark.'}
    }
    cmux-run [identify --json] | from json | get caller
}

# The caller's workspace record from `workspace list`, which only covers one
# window, hence the scoping to the caller's.
def workspace [target: record]: nothing -> record {
    let found = cmux-run [workspace list --json --window $target.window_ref]
    | from json
    | get workspaces
    | where ref == $target.workspace_ref

    if ($found | is-empty) {
        error make {msg: $"Workspace ($target.workspace_ref) not found in ($target.window_ref)."}
    }
    $found | first
}

def workspace-action [target: record, args: list<string>]: nothing -> nothing {
    cmux-run [
        workspace-action
        --window
        $target.window_ref
        --workspace
        $target.workspace_ref
        ...$args
    ]
    | ignore
}

# Split a description into the goal (first line, prefix stripped) and the
# user's own lines below it. A description without the prefix is all notes.
def split-description [description: string]: nothing -> record {
    let lines = $description | lines
    match $lines {
        [$first, ..$rest] if ($first | str starts-with $GOAL_PREFIX) => {
            # Without --all, `str replace` drops only the first match: the prefix.
            {
                goal: ($first | str replace $GOAL_PREFIX '' | str trim)
                notes: $rest
            }
        }
        _ => {goal: null, notes: $lines}
    }
}

# The marker as the skills report it.
def marker [ws: record]: nothing -> record {
    let description = $ws.description? | default ''
    {
        goal: (split-description $description).goal
        color: $ws.custom_color?
        pinned: $ws.pinned
        description: $description
    }
}

# Compare what cmux reports with what was written, field by field.
def verify [target: record, expected: record]: nothing -> record {
    let actual = marker (workspace $target)
    let mismatches = $expected
    | columns
    | where {|field| ($actual | get $field) != ($expected | get $field) }

    if ($mismatches | is-not-empty) {
        let detail = $mismatches
        | each {|field| $"($field): expected ($expected | get $field | to json --raw), got ($actual | get $field | to json --raw)" }
        | str join '; '
        error make {msg: $"cmux did not apply the marker — ($detail)"}
    }
    $actual
}

def main []: nothing -> nothing {
    print (help main)
}

# Mark the goal: set the quadrant's colour and pin state, and make the goal the
# description's first line while keeping the user's own lines below it.
def "main set" [
    quadrant: string # DO, PLAN, DELEGATE or DROP
    goal: string # one line; a leading `ゴール:` is accepted and dropped
]: nothing -> nothing {
    let key = $quadrant | str uppercase
    let style = $QUADRANTS | get -o $key
    if $style == null {
        error make {msg: $"Unknown quadrant '($quadrant)'. Use one of: ($QUADRANTS | columns | str join ', ')."}
    }

    let goal = $goal | str trim | str replace --regex $"^($GOAL_PREFIX)\\s*" ''
    if ($goal | is-empty) or ($goal | str contains "\n") {
        error make {msg: 'The goal must be a single non-empty line.'}
    }

    let target = caller
    let notes = (split-description ((workspace $target).description? | default '')).notes
    let description = [$"($GOAL_PREFIX) ($goal)" ...$notes] | str join "\n"

    workspace-action $target [--action set-color --color $style.color]
    workspace-action $target [
        --action
        (if $style.pin { 'pin' } else { 'unpin' })
    ]
    workspace-action $target [--action set-description --description $description]

    # cmux may normalise the hex case, so compare against what it reports.
    let applied = verify $target {pinned: $style.pin, description: $description}
    if ($applied.color | default '' | str uppercase) != $style.color {
        error make {msg: $"cmux did not apply the colour — expected ($style.color), got ($applied.color | to json --raw)"}
    }

    $applied | insert quadrant $key | to json --raw | print
}

# Clear the marker: unpin, clear the colour and remove the goal line, keeping
# the user's own lines. A description without a goal line is left as it is,
# since focus did not write it.
def "main clear" [
    --close # then close the caller's own tab, ending the session running in it
]: nothing -> nothing {
    let target = caller
    let original = (workspace $target).description? | default ''
    let current = split-description $original
    let description = if $current.goal == null {
        $original
    } else {
        $current.notes | str join "\n"
    }

    workspace-action $target [--action unpin]
    workspace-action $target [--action clear-color]
    if $current.goal != null {
        if ($description | is-empty) {
            workspace-action $target [--action clear-description]
        } else {
            workspace-action $target [--action set-description --description $description]
        }
    }

    verify $target {
        goal: null
        color: null
        pinned: false
        description: $description
    }
    | insert cleared_goal $current.goal
    | to json --raw
    | print

    # Last, because it kills the caller. --force is required since the session
    # that asked for this is still running in the tab.
    if $close {
        cmux-run [
            close-surface
            --force
            --window
            $target.window_ref
            --workspace
            $target.workspace_ref
            --surface
            $target.surface_ref
        ]
        | ignore
    }
}

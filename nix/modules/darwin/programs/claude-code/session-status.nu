# claude-session-status: shows whether a session can be closed in the cmux
# sidebar, and reads those states back across workspaces for the `sweep` skill.
#
# Two pills are written. `session_done` holds the verdict of the `done` skill,
# and `session_git` warns about work a closed session would strand. A workspace
# with neither pill has nothing to report, which keeps the sidebar quiet.

const VERDICT_KEY = 'session_done'
const GIT_KEY = 'session_git'

const VERDICTS = {
    ok: {label: '消してOK', color: '#2ECC71'}
    remaining: {label: '残あり', color: '#F1C40F'}
}

const GIT_COLOR = '#E67E22'

# `claude_code` holds one of these labels while a Claude Code session waits for
# input. Sessions started under different locales report different labels.
const IDLE_STATES = ['待機中' 'Idle']

# Other sessions commit here too, so its state says nothing about this session.
const SHARED_BRANCHES = [main master]

def in-cmux []: nothing -> bool {
    $env.CMUX_WORKSPACE_ID? | is-not-empty
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

# What would be stranded if the session in the current directory closed, or
# null when nothing would be. Every case that cannot be judged is null, because
# a hook must not invent a warning.
def git-warning []: nothing -> any {
    let branch = ^git branch --show-current | complete
    if $branch.exit_code != 0 {
        return null
    }
    # An empty name means a detached HEAD, which no later push would publish.
    if ($branch.stdout | str trim) in $SHARED_BRANCHES {
        return null
    }

    let status = ^git status --porcelain | complete
    if $status.exit_code == 0 and ($status.stdout | str trim | is-not-empty) {
        return '未コミット'
    }

    # Compared with every remote rather than the upstream, so a new branch that
    # has no upstream yet still counts its commits.
    let ahead = ^git rev-list --count HEAD --not --remotes | complete
    if $ahead.exit_code == 0 and ($ahead.stdout | str trim) != '0' {
        return '未push'
    }
    null
}

# Parse `list-status` lines such as `claude_code=待機中 icon=pause color=#8E8E93`
# into {claude_code: 待機中}. Values may contain spaces, so a value ends at the
# first metadata field rather than at the first space.
def parse-status []: string -> record {
    $in
    | lines
    | parse --regex '^(?<key>\w+)=(?<value>.*?)(?: (?:icon|color|priority|work)=.*)?$'
    | reduce --fold {} {|row, acc| $acc | upsert $row.key $row.value }
}

def main []: nothing -> nothing {
    print (help main)
}

# Show the `done` skill's verdict. Outside cmux there is no sidebar, so it does
# nothing.
def "main verdict" [
    verdict: string # ok or remaining
]: nothing -> nothing {
    let style = $VERDICTS | get -o $verdict
    if $style == null {
        error make {msg: $"Unknown verdict '($verdict)'. Use one of: ($VERDICTS | columns | str join ', ')."}
    }
    if not (in-cmux) {
        return
    }
    cmux-run [
        set-status
        $VERDICT_KEY
        $style.label
        --color
        $style.color
        --priority
        '90'
    ] | ignore
}

# Drop the verdict, because any new prompt can invalidate it. Runs as a
# UserPromptSubmit hook, so a failure must never get in the way of the prompt.
def "main reset" []: nothing -> nothing {
    if not (in-cmux) {
        return
    }
    try {
        cmux-run [clear-status $VERDICT_KEY] | ignore
    }
}

# Update the git warning. Runs as a Stop hook, so a failure must never get in
# the way of the session.
def "main refresh" []: nothing -> nothing {
    if not (in-cmux) {
        return
    }
    try {
        let warning = git-warning
        if $warning == null {
            cmux-run [clear-status $GIT_KEY] | ignore
        } else {
            cmux-run [
                set-status
                $GIT_KEY
                $warning
                --color
                $GIT_COLOR
                --priority
                '80'
            ] | ignore
        }
    }
}

# Print every other workspace in the caller's window as JSON. `verdict` and
# `surface` are set only when one terminal is there, because with several there
# is no telling which session the verdict covers or which one would receive
# `/done`, and `/done` sent to a shell would run as a command.
def "main sweep" []: nothing -> nothing {
    if not (in-cmux) {
        error make {msg: 'Not inside cmux ($CMUX_WORKSPACE_ID is unset): there are no workspaces to sweep.'}
    }
    let caller = cmux-run [identify --json] | from json | get caller

    cmux-run [workspace list --json --window $caller.window_ref]
    | from json
    | get workspaces
    | where ref != $caller.workspace_ref
    | par-each --keep-order {|ws|
        let status = cmux-run [list-status --window $caller.window_ref --workspace $ws.ref] | parse-status
        let terminals = cmux-run [tree --window $caller.window_ref --workspace $ws.ref --json]
        | from json
        | get windows.0.workspaces.0.panes
        | get surfaces
        | flatten
        | where type == 'terminal'
        let state = $status | get -o claude_code
        let single = ($terminals | length) == 1

        {
            ref: $ws.ref
            title: $ws.title
            state: $state
            verdict: (if $single { $status | get -o $VERDICT_KEY }), 
            git: ($status | get -o $GIT_KEY), 
            surface: (if $single and $state in $IDLE_STATES { $terminals.0.ref })
        }
    }
    | to json
    | print
}

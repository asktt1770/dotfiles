#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell --command nu

# Claude Code UserPromptSubmit hook: the derailment guard of the `focus` skill.
#
# The caller's cmux workspace description is the single source of truth for
# the main goal, so the goal survives /clear and new sessions in the same
# workspace. When that description starts with GOAL_PREFIX, the goal and the
# guard rule are injected into the context; otherwise the hook prints nothing.
#
# Every failure path is silent: this runs before every prompt, and a broken
# cmux socket must never block or clutter the conversation.

# Written by the `focus` skill and cleared by `unfocus`; keep the three in sync.
const GOAL_PREFIX = 'ゴール:'

# Parsed `--json` output of a cmux command, or null when cmux fails. The
# arguments come as a list because a rest parameter would parse cmux's own
# flags as this command's.
def cmux-json [args: list<string>]: nothing -> any {
    let result = ^cmux ...$args --json | complete

    if $result.exit_code != 0 {
        null
    } else {
        try {
            $result.stdout | from json
        } catch { null }
    }
}

def guard-context [goal: string]: nothing -> string {
    [
        $"Current main goal \(from this cmux workspace's description\): ($goal)"
        ''
        'Derailment guard: if this prompt asks for work that does not serve that goal, do not start it and do not refuse it.'
        'Ask with AskUserQuestion instead: park it as a GitHub issue / add it to the cmux todo list / switch the main goal to it.'
        "Follow the `focus` skill's \"Derailment guard\" section for where to park and how to switch, then return to the goal."
        'Work that serves the goal, quick questions, follow-ups, /focus and /unfocus proceed normally.'
    ] | str join "\n"
}

def main [] {

    # Outside cmux there is no workspace to read.
    if ($env.CMUX_WORKSPACE_ID? | is-empty) or (which cmux | is-empty) {
        return
    }

    let caller = cmux-json [identify] | get -o caller
    if $caller == null {
        return
    }

    # `workspace list` only covers one window, so scope it to the caller's.
    let description = cmux-json [workspace list '--window' $caller.window_ref]
    | get -o workspaces
    | default []
    | where ref == $caller.workspace_ref
    | get -o 0.description
    | default ''

    if not ($description | str starts-with $GOAL_PREFIX) {
        return
    }

    # The goal is the first line; anything below it is the user's own notes.
    # Without --all, `str replace` drops only the first match: the prefix itself.
    let goal = $description | lines | first | str replace $GOAL_PREFIX '' | str trim
    if ($goal | is-empty) {
        return
    }

    {
        hookSpecificOutput: {
            hookEventName: 'UserPromptSubmit'
            additionalContext: (guard-context $goal)
        }
    } | to json --raw | print
}

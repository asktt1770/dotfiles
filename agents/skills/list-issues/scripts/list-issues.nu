#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

# Print the user's open issues, grouped by who acts next and most pressing first.
#
# Usage: list-issues.nu [--all]   # --all spans every repository

# Days without an update before an issue is flagged. A must-do should not sit
# for more than a week; a nice-to-have gets a quarter before closing it is worth
# asking about.
const MUST_OVERDUE_DAYS = 7
const NICE_CLOSE_DAYS = 90

# GitHub search returns at most 1000 results.
const SEARCH_LIMIT = 1000

const SECTIONS = [
    {label: 'human:todo', heading: 'あなた待ち（human:todo）'}
    {label: 'agent:ready', heading: '任せられる（agent:ready）'}
    {label: 'agent:investigate', heading: '調査を頼める（agent:investigate）'}
]

# Rank for sorting: `p:must` first, unprioritised between it and `p:nice`, so an
# unjudged issue is not buried under the ones explicitly marked as optional.
def priority-rank [priority: string]: nothing -> int {
    match $priority {
        'must' => 0
        'nice' => 2
        _ => 1
    }
}

def flag [priority: string, days: int]: nothing -> string {
    match $priority {
        'must' if $days >= $MUST_OVERDUE_DAYS => '  ! 要対応'
        'nice' if $days >= $NICE_CLOSE_DAYS => '  ? 閉じますか'
        _ => ''
    }
}

def fetch-issues [all: bool]: nothing -> table {
    let scope = if $all {
        []
    } else {
        [
            --repo
            (^gh repo view --json nameWithOwner --jq .nameWithOwner)
        ]
    }

    ^gh search issues --author '@me' --state open --limit $SEARCH_LIMIT --json number,title,labels,updatedAt,repository ...$scope
    | from json
    | each {|issue|
        let labels = $issue.labels | each { get name }
        let priority = if 'p:must' in $labels {
            'must'
        } else if 'p:nice' in $labels {
            'nice'
        } else {
            '-'
        }

        let ref = if $all { $'($issue.repository.nameWithOwner)#($issue.number)' } else { $'#($issue.number)' }
        let rank = priority-rank $priority
        let days = ((date now) - ($issue.updatedAt | into datetime)) / 1day | math floor

        {
            ref: $ref
            title: $issue.title
            labels: $labels
            priority: $priority
            rank: $rank
            days: $days
        }
    }
}

def render-section [issues: table, section: record]: nothing -> list<string> {
    let rows = $issues
    | where { $section.label in $in.labels }
    # Within a priority, the issue untouched the longest comes first.
    | sort-by rank { -1 * $in.days }
    | each {|row| $'  ($row.priority | fill --width 4)  ($row.ref)  ($row.title)  ($row.days)日放置(flag $row.priority $row.days)' }

    if ($rows | is-empty) { [] } else { [$section.heading ...$rows ''] }
}

def main [--all]: nothing -> string {
    let issues = fetch-issues $all
    let queue_labels = $SECTIONS | get label
    let unsorted = $issues | where {|row| $row.labels | all { $in not-in $queue_labels } } | length

    $SECTIONS
    | each {|section| render-section $issues $section }
    | flatten
    | append $'未分類（ラベルなし）: ($unsorted)件'
    | str join "\n"
}

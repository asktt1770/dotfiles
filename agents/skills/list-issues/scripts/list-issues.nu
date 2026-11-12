#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

# Print the user's open issues: queue leaves grouped by who acts next and most
# pressing first, then parent issues with their sub-issue progress.
#
# Usage: list-issues.nu [--all]   # --all spans every repository

# Days without an update before an issue is flagged. A must-do should not sit
# for more than a week; a nice-to-have gets a quarter before closing it is worth
# asking about.
const MUST_OVERDUE_DAYS = 7
const NICE_CLOSE_DAYS = 90

# GraphQL rather than `gh search issues`, because only GraphQL returns the parent
# and sub-issue progress that decide where an issue is listed. GitHub search
# stops at 1000 results, which `--paginate` cannot exceed. Labels take one page
# of 100, the API maximum, so no queue or priority label is cut off.
const QUERY = '
query($q: String!, $endCursor: String) {
  search(query: $q, type: ISSUE, first: 100, after: $endCursor) {
    pageInfo { hasNextPage endCursor }
    nodes {
      ... on Issue {
        number
        title
        updatedAt
        repository { nameWithOwner }
        labels(first: 100) { nodes { name } }
        parent { number repository { nameWithOwner } }
        subIssuesSummary { total completed }
      }
    }
  }
}'

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

def fetch-issues [all: bool]: nothing -> list<record> {
    let scope = if $all {
        ''
    } else {
        $' repo:(^gh repo view --json nameWithOwner --jq .nameWithOwner)'
    }

    let result = ^gh api graphql --paginate -f $'query=($QUERY)' -f $'q=author:@me is:issue is:open($scope)' --jq '.data.search.nodes[]' | complete

    # Without this, a failed request would print an empty queue as if complete.
    if $result.exit_code != 0 {
        error make {msg: $'gh api graphql failed: ($result.stderr | str trim)'}
    }

    $result.stdout | lines | each { from json }
}

# Flatten one GraphQL issue into the fields the sections render.
def to-row [all: bool]: record -> record {
    let issue = $in
    let labels = $issue.labels.nodes | each { get name }
    let priority = if 'p:must' in $labels {
        'must'
    } else if 'p:nice' in $labels {
        'nice'
    } else {
        '-'
    }
    let prefix = if $all { $issue.repository.nameWithOwner } else { '' }
    let parent = if $issue.parent == null {
        ''
    } else {
        # A parent may live in another repository, so qualify it whenever it differs.
        let parent_repo = $issue.parent.repository.nameWithOwner
        let parent_prefix = if $all or $parent_repo != $issue.repository.nameWithOwner { $parent_repo } else { '' }
        $'（親 ($parent_prefix)#($issue.parent.number)）'
    }
    let rank = priority-rank $priority
    let days = ((date now) - ($issue.updatedAt | into datetime)) / 1day | math floor

    {
        ref: $'($prefix)#($issue.number)'
        title: $issue.title
        labels: $labels
        priority: $priority
        rank: $rank
        days: $days
        parent: $parent
        children: $issue.subIssuesSummary.total
        done: $issue.subIssuesSummary.completed
    }
}

def render-section [leaves: list<record>, section: record]: nothing -> list<string> {
    let rows = $leaves
    | where { $section.label in $in.labels }
    # Within a priority, the issue untouched the longest comes first.
    | sort-by rank { -1 * $in.days }
    | each {|row| $'  ($row.priority | fill --width 4)  ($row.ref)  ($row.title)($row.parent)  ($row.days)日放置(flag $row.priority $row.days)' }

    if ($rows | is-empty) { [] } else { [$section.heading ...$rows ''] }
}

def render-parents [parents: list<record>]: nothing -> list<string> {
    let rows = $parents
    | sort-by { -1 * $in.days }
    | each {|row|
        let close = if $row.done == $row.children { '  ? 全部済み、閉じますか' } else { '' }
        $'  ($row.ref)  ($row.title)  子 ($row.done)/($row.children) 完了($close)'
    }

    if ($rows | is-empty) { [] } else { ['進行中の問題（親）' ...$rows ''] }
}

# Render already-fetched rows; separate from `main` so it can run on fixtures.
def render [issues: list<record>]: nothing -> string {
    let parents = $issues | where children > 0
    let leaves = $issues | where children == 0
    let queue_labels = $SECTIONS | get label
    let unsorted = $leaves | where {|row| $row.labels | all { $in not-in $queue_labels } } | length

    $SECTIONS
    | each {|section| render-section $leaves $section }
    | flatten
    | append (render-parents $parents)
    | append $'未分類（ラベルなし）: ($unsorted)件'
    | str join "\n"
}

def main [--all]: nothing -> string {
    render (fetch-issues $all | each { to-row $all })
}

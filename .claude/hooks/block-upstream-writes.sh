#!/usr/bin/env bash
# Guard: block any write that targets the upstream repo (ryoppippi/dotfiles).
#
# This repository is a personal fork. Contributions must only ever go to the
# origin remote (asktt1770/dotfiles). Pushing to, or opening pull requests
# against, the upstream owner (ryoppippi) is forbidden — we have no relationship
# with that owner and only fork to learn from their configuration.
#
# Registered as a PreToolUse hook for the Bash tool. The hook receives the tool
# invocation as JSON on stdin; exiting with code 2 blocks the call and feeds the
# stderr message back to Claude so it knows the action is disallowed.
#
# Read-only access to upstream (git fetch/pull upstream, gh pr list/view) is
# intentionally NOT blocked — learning from upstream is the whole point.
set -euo pipefail

# Read the hook payload and extract the command string the Bash tool wants to run.
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

# Collapse newlines so multi-line commands match as a single string.
norm="$(printf '%s' "$cmd" | tr '\n' ' ')"

# Emit a blocking decision (exit 2) with an explanation Claude can act on.
deny() {
  printf 'BLOCKED: this is a fork — writing to upstream (ryoppippi/dotfiles) is forbidden.\n' >&2
  printf 'Matched rule: %s\n' "$1" >&2
  printf 'All pushes and pull requests must target origin (asktt1770/dotfiles).\n' >&2
  exit 2
}

# 1. A git push that names the upstream remote or any ryoppippi URL.
#    Match the `push` *subcommand* only — `git push` or `git <-flags> push` —
#    so that `git stash push` (and other `git <subcmd> push` forms) does not
#    trigger a false positive. The remote/URL check uses a remote-ish boundary
#    so the literal word "upstream" inside an unrelated token (e.g. a commit
#    message like "block-upstream-pr") is not mistaken for the upstream remote.
if printf '%s' "$norm" | grep -Eq '(^|[^[:alnum:]])git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*push\b' &&
  printf '%s' "$norm" | grep -Eq '(^|[[:space:]])upstream([[:space:]]|$)|ryoppippi'; then
  deny "git push targeting upstream/ryoppippi"
fi

# 2. Opening a pull request whose target repo is ryoppippi.
if printf '%s' "$norm" | grep -Eq '\bgh\b.*\bpr\b.*\bcreate\b' &&
  printf '%s' "$norm" | grep -Eq 'ryoppippi'; then
  deny "gh pr create targeting ryoppippi"
fi

# 3. A mutating gh api call (POST/PUT/PATCH/DELETE) against a ryoppippi repo.
if printf '%s' "$norm" | grep -Eq '\bgh\b.*\bapi\b' &&
  printf '%s' "$norm" | grep -Eq 'ryoppippi' &&
  printf '%s' "$norm" | grep -Eq -- '-X[[:space:]=]*(POST|PUT|PATCH|DELETE)|--method[[:space:]=]*(POST|PUT|PATCH|DELETE)'; then
  deny "mutating gh api call targeting ryoppippi"
fi

# Nothing matched — allow the command through unchanged.
exit 0

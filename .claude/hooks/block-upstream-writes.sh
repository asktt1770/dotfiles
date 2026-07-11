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
#
# The command is parsed *structurally* (tokenise, then locate subcommands, flags
# and their values) rather than by loose substring matching, so that:
#   - `git -c k=v push upstream` is still caught (multi-token global options),
#   - `gh pr create --body "... ryoppippi ..."` is NOT a false positive (only
#     the --repo/-R target is inspected, never free-form text),
#   - `gh api repos/ryoppippi/... -f k=v` is caught (field flags imply POST).
set -euo pipefail

# Read the hook payload and extract the command string the Bash tool wants to run.
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

# Collapse newlines so a multi-line command is analysed as a single string.
norm="$(printf '%s' "$cmd" | tr '\n' ' ')"

# The protected upstream owner. A write is denied only when its resolved target
# (push remote/URL, PR repo, or API endpoint) names this owner.
UPSTREAM_OWNER='ryoppippi'

# Emit a blocking decision (exit 2) with an explanation Claude can act on.
deny() {
  printf 'BLOCKED: this is a fork — writing to upstream (%s/dotfiles) is forbidden.\n' "$UPSTREAM_OWNER" >&2
  printf 'Matched rule: %s\n' "$1" >&2
  printf 'All pushes and pull requests must target origin (asktt1770/dotfiles).\n' >&2
  exit 2
}

# Strip a single layer of surrounding single/double quotes from a token, so a
# quoted argument like "ryoppippi/dotfiles" is compared by its bare value.
sq() {
  local t="$1"
  t="${t#[\"\']}"
  t="${t%[\"\']}"
  printf '%s' "$t"
}

# Tokenise the normalised command on whitespace. This is a heuristic split, not
# a full shell parse: we only ever inspect subcommands, option flags and their
# immediate values, never free text, so quoting nuances in message/body
# arguments cannot change the decision. `|| true` keeps an empty command from
# tripping `set -e` (read returns non-zero at EOF).
TOKENS=()
read -ra TOKENS <<<"$norm" || true
N=${#TOKENS[@]}

# Index (into TOKENS) of the first token whose bare value equals $1, or -1.
index_of() {
  local want="$1" i
  for ((i = 0; i < N; i++)); do
    [[ "$(sq "${TOKENS[i]}")" == "$want" ]] && {
      printf '%s' "$i"
      return 0
    }
  done
  printf '%s' "-1"
}

# --- rule 1: git push to upstream ---------------------------------------

# Return success if the git *subcommand* is `push`. We start after the `git`
# token and skip global options; the ones below consume a following value token,
# so we advance past both. The first non-option token is the subcommand — this
# is what tells `git push` apart from `git stash push`.
git_subcommand_is_push() {
  local gi
  gi="$(index_of git)"
  [[ $gi == "-1" ]] && return 1
  local i=$((gi + 1)) t
  while ((i < N)); do
    t="$(sq "${TOKENS[i]}")"
    case "$t" in
    # Global options that consume the NEXT token as their value.
    -C | -c | --git-dir | --work-tree | --namespace | --super-prefix | --exec-path | --config-env)
      i=$((i + 2))
      ;;
    # Any other option (including --opt=value) consumes only itself.
    -*)
      i=$((i + 1))
      ;;
    # First non-option token is the subcommand.
    *)
      [[ $t == "push" ]] && return 0
      return 1
      ;;
    esac
  done
  return 1
}

# Return success if a confirmed `git push` names the upstream remote or a
# ryoppippi URL. Only the positional arguments after `push` are inspected;
# option flags such as --force are skipped.
push_targets_upstream() {
  local gi i t pi=-1
  gi="$(index_of git)"
  for ((i = gi + 1; i < N; i++)); do
    [[ "$(sq "${TOKENS[i]}")" == "push" ]] && {
      pi=$i
      break
    }
  done
  ((pi < 0)) && return 1
  for ((i = pi + 1; i < N; i++)); do
    t="$(sq "${TOKENS[i]}")"
    [[ $t == -* ]] && continue
    [[ $t == "upstream" || $t == *"$UPSTREAM_OWNER"* ]] && return 0
  done
  return 1
}

if git_subcommand_is_push && push_targets_upstream; then
  deny "git push targeting upstream/$UPSTREAM_OWNER"
fi

# --- gh command path -----------------------------------------------------

# Echo the gh command path as "<group> <subcommand>" (e.g. "pr create",
# "api repos/…"), skipping global options and the value of -R/--repo/--hostname
# so an option value is never mistaken for the command path. Empty if not gh.
gh_command_path() {
  local gi
  gi="$(index_of gh)"
  [[ $gi == "-1" ]] && return 0
  local i=$((gi + 1)) t
  local out=()
  while ((i < N)) && ((${#out[@]} < 2)); do
    t="$(sq "${TOKENS[i]}")"
    case "$t" in
    -R | --repo | --hostname) i=$((i + 2)) ;; # option + its value
    -*) i=$((i + 1)) ;;                       # value-less / inline-value option
    *)
      out+=("$t")
      i=$((i + 1))
      ;;
    esac
  done
  printf '%s' "${out[*]:-}"
}

GH_PATH="$(gh_command_path)"
GH_GROUP="${GH_PATH%% *}"

# --- rule 2: gh pr create targeting ryoppippi ---------------------------

# Echo the value of the --repo/-R flag (supporting `--repo v`, `--repo=v`,
# `-R v`, `-R=v`), or empty if the flag is absent. When absent, the base repo is
# resolved from gh's default (see the caller), which in a fork can be the
# upstream parent — so an empty result is NOT assumed safe.
flag_value_repo() {
  local i t
  for ((i = 0; i < N; i++)); do
    t="$(sq "${TOKENS[i]}")"
    case "$t" in
    --repo=*)
      printf '%s' "${t#--repo=}"
      return 0
      ;;
    -R=*)
      printf '%s' "${t#-R=}"
      return 0
      ;;
    --repo | -R)
      ((i + 1 < N)) && printf '%s' "$(sq "${TOKENS[i + 1]}")"
      return 0
      ;;
    esac
  done
  return 0
}

if [[ $GH_PATH == "pr create" ]]; then
  repo="$(flag_value_repo)"
  # A bare `gh pr create` (no --repo/-R) does not target origin by default: gh
  # resolves the base repo from its configured default (git config
  # remote.*.gh-resolved / `gh repo set-default`), and for a fork that default
  # can be the upstream parent. So when --repo is omitted, resolve the base repo
  # gh would actually use and refuse to proceed if it cannot be confirmed safe.
  if [[ -z $repo ]]; then
    repo="$(gh repo set-default --view 2>/dev/null || true)"
    [[ -z $repo ]] && deny "gh pr create without --repo and no resolvable default base repo (pass --repo asktt1770/dotfiles)"
  fi
  [[ $repo == *"$UPSTREAM_OWNER"* ]] && deny "gh pr create targeting $UPSTREAM_OWNER"
fi

# --- rule 3: mutating gh api against ryoppippi --------------------------

# Echo the endpoint (first positional argument) of a `gh api` call, skipping
# options and the values consumed by value-taking options. Empty if none.
gh_api_endpoint() {
  local gi i t ai=-1
  gi="$(index_of gh)"
  for ((i = gi + 1; i < N; i++)); do
    [[ "$(sq "${TOKENS[i]}")" == "api" ]] && {
      ai=$i
      break
    }
  done
  ((ai < 0)) && return 0
  i=$((ai + 1))
  while ((i < N)); do
    t="$(sq "${TOKENS[i]}")"
    case "$t" in
    # gh api options that consume the NEXT token as their value.
    -X | --method | -f | --raw-field | -F | --field | -H | --header | --hostname | --input | -q | --jq | -t | --template | --cache)
      i=$((i + 2))
      ;;
    -*) i=$((i + 1)) ;; # value-less or inline-value option
    *)
      printf '%s' "$t" # first positional = endpoint
      return 0
      ;;
    esac
  done
  return 0
}

# Return success if a `gh api` call performs a write. gh defaults to GET but
# auto-switches to POST when a field flag (-f/-F/--field/--raw-field/--input) is
# present; -X/--method sets the method explicitly. A write is any method in
# {POST,PUT,PATCH,DELETE}; an explicit GET (even with fields) counts as a read.
gh_api_is_write() {
  local i t method="" has_field=0
  for ((i = 0; i < N; i++)); do
    t="$(sq "${TOKENS[i]}")"
    case "$t" in
    -X | --method) ((i + 1 < N)) && method="$(sq "${TOKENS[i + 1]}")" ;;
    -X=*) method="${t#-X=}" ;;
    --method=*) method="${t#--method=}" ;;
    -f | --raw-field | -F | --field | --input) has_field=1 ;;
    esac
  done
  # Upper-case the method for comparison (bash 3.2 has no ${var^^}).
  method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  if [[ -n $method ]]; then
    case "$method" in
    POST | PUT | PATCH | DELETE) return 0 ;;
    *) return 1 ;;
    esac
  fi
  # No explicit method: the presence of a field flag implies POST.
  ((has_field == 1)) && return 0
  return 1
}

if [[ $GH_GROUP == "api" ]]; then
  endpoint="$(gh_api_endpoint)"
  if [[ $endpoint == *"$UPSTREAM_OWNER"* ]] && gh_api_is_write; then
    deny "mutating gh api call targeting $UPSTREAM_OWNER"
  fi
fi

# Nothing matched — allow the command through unchanged.
exit 0

#!/usr/bin/env bash
# Guard: forbid destructive git ops that mutate the MAIN checkout of this repo.
#
# This repository's dotfiles are live-symlinked into ~/.config from the main
# checkout, so a `git merge`/`git switch -c`/`git reset --hard`/… executed there
# rewrites the user's live environment instantly. This is the Bash-side companion
# to require-worktree-edit.sh: that hook watches Edit/Write, this one watches the
# `git` commands (a Bash tool call) that the edit hook cannot see.
#
# Registered as a PreToolUse hook for the Bash tool. The hook receives the tool
# invocation as JSON on stdin; exiting 2 blocks the call and feeds the stderr
# message back to Claude so it knows the action is disallowed.
#
# The command is parsed *structurally* (tokenise, then locate the subcommand,
# flags and their values) rather than by loose substring matching, mirroring
# block-upstream-writes.sh, so that e.g. `git -c k=v merge` is still caught and a
# branch named "main-ish" is not mistaken for "main".
#
# Known limitation: only the effective working directory is inspected — `.cwd`,
# or the first `git -C <path>` value when present. A command that changes
# directory itself (`cd /main && git merge`) is NOT seen here, because `.cwd`
# still reports the pre-cd directory. cwd/-C coverage is enough for the way
# Claude issues commands; the Edit/Write hook covers the file-mutation path.
set -euo pipefail

# Read the hook payload: the command string to run and the directory it runs in.
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // ""')"

# Collapse newlines so a multi-line command is analysed as a single string.
norm="$(printf '%s' "$cmd" | tr '\n' ' ')"

# Emit a blocking decision (exit 2) with an explanation Claude can act on.
deny() {
  printf "BLOCKED: '%s' mutates the main checkout, whose dotfiles are live-symlinked from ~/.config.\n" "$1" >&2
  printf 'Do this work in a worktree instead: use the EnterWorktree tool, then run the command there. See CLAUDE.md > Worktree Workflow.\n' >&2
  exit 2
}

# Strip a single layer of surrounding single/double quotes from a token, so a
# quoted argument like "main" is compared by its bare value.
sq() {
  local t="$1"
  t="${t#[\"\']}"
  t="${t%[\"\']}"
  printf '%s' "$t"
}

# Tokenise the normalised command on whitespace. Heuristic split, not a full
# shell parse: we only ever inspect the subcommand, option flags and their
# immediate values, never free text. `|| true` keeps an empty command from
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

# --- locate the git invocation and its subcommand -------------------------

# git's global options that consume the NEXT token as their value. We must skip
# both so an option value is never mistaken for the subcommand or a positional.
git_opt_takes_value() {
  case "$1" in
  -C | -c | --git-dir | --work-tree | --namespace | --super-prefix | --exec-path | --config-env) return 0 ;;
  *) return 1 ;;
  esac
}

GI="$(index_of git)"
# No bare `git` token -> not a git command we guard -> allow.
[[ $GI == "-1" ]] && exit 0

# Walk the tokens after `git`, skipping global options, to find the subcommand
# (first non-option token) and its position. Also capture the first `-C <path>`
# value, which redirects git at another directory.
SUB=""
SUB_IDX=-1
DASH_C=""
i=$((GI + 1))
while ((i < N)); do
  t="$(sq "${TOKENS[i]}")"
  if [[ $t == "-C" ]]; then
    # `-C <path>`: remember the path, then skip both tokens.
    ((i + 1 < N)) && [[ -z $DASH_C ]] && DASH_C="$(sq "${TOKENS[i + 1]}")"
    i=$((i + 2))
    continue
  fi
  if git_opt_takes_value "$t"; then
    i=$((i + 2)) # value-taking global option: skip option + value
    continue
  fi
  if [[ $t == -* ]]; then
    i=$((i + 1)) # value-less / inline-value global option: skip itself
    continue
  fi
  SUB="$t" # first non-option token is the subcommand
  SUB_IDX=$i
  break
done

# No subcommand (bare `git`) -> nothing destructive -> allow.
[[ -z $SUB ]] && exit 0

# --- decide whether the effective directory is THIS repo's main checkout ---

# Effective directory = the `git -C <path>` value if given, else the tool's cwd.
# A relative -C path is resolved against cwd.
effdir="$cwd"
if [[ -n $DASH_C ]]; then
  case "$DASH_C" in
  /*) effdir="$DASH_C" ;;
  *) effdir="${cwd%/}/$DASH_C" ;;
  esac
fi
# Fall back to the current directory when cwd is absent from the payload.
[[ -z $effdir ]] && effdir="."

# Resolve the git-dir of the repo the effective directory belongs to. Not a repo
# -> allow.
gitdir="$(git -C "$effdir" rev-parse --path-format=absolute --git-dir 2>/dev/null)" || exit 0

# Inside a worktree -> allow (this is exactly where work is supposed to happen).
case "$gitdir" in */worktrees/*) exit 0 ;; esac

# It's a main checkout. Scope strictly to THIS project's repo family via the
# shared git-common-dir, so we never block git ops in some unrelated repo.
eff_common="$(git -C "$effdir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0
proj_common="$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0
[ "$eff_common" = "$proj_common" ] || exit 0

# --- classify the subcommand as destructive or not ------------------------

# Bare value of the first positional argument after the subcommand (skipping
# option flags and a `--` separator), or empty. Used to inspect switch/checkout
# targets. `--` and any option token count as non-positional.
first_positional_after_sub() {
  local j t
  for ((j = SUB_IDX + 1; j < N; j++)); do
    t="$(sq "${TOKENS[j]}")"
    [[ $t == "--" ]] && continue
    [[ $t == -* ]] && continue
    printf '%s' "$t"
    return 0
  done
  return 0
}

# True if any token after the subcommand equals one of the given flags.
sub_has_flag() {
  local want j t
  for want in "$@"; do
    for ((j = SUB_IDX + 1; j < N; j++)); do
      t="$(sq "${TOKENS[j]}")"
      [[ $t == "$want" ]] && return 0
    done
  done
  return 1
}

# True if any token after the subcommand is a short flag with an INLINE value,
# e.g. `-cfoo` for `-c` (git accepts `git switch -cfoo` / `git checkout -bfoo`).
# sub_has_flag only matches exact tokens and first_positional_after_sub skips
# anything starting with `-`, so without this an inline-value create flag would
# slip straight through to the allow branch — a guardrail bypass.
sub_has_inline_short() {
  local want j t
  for want in "$@"; do
    for ((j = SUB_IDX + 1; j < N; j++)); do
      t="$(sq "${TOKENS[j]}")"
      # `${want}?*` = the flag followed by at least one more character.
      [[ $t == "${want}"?* ]] && return 0
    done
  done
  return 1
}

case "$SUB" in
# Integration and history-rewriting ops always mutate the checkout's tree/HEAD.
merge | rebase | cherry-pick | am | apply | commit | revert)
  deny "git $SUB"
  ;;
# reset only rewrites the working tree with --hard/--merge/--keep; a plain/mixed
# reset just moves HEAD/index, but on the main checkout that still corrupts the
# live branch state, so block the tree-touching variants explicitly.
reset)
  sub_has_flag --hard --merge --keep && deny "git reset (working-tree reset)"
  ;;
# restore rewrites tracked files in the working tree (and/or index).
restore)
  deny "git restore"
  ;;
# stash pop/apply re-applies changes onto the main checkout's working tree.
stash)
  case "$(first_positional_after_sub)" in
  pop | apply) deny "git stash $(first_positional_after_sub)" ;;
  esac
  ;;
# switch/checkout: block creating a branch, or moving OFF main. Moving to main
# (or `git switch -`, which we treat as harmless) is allowed so the main checkout
# can be returned to a safe state.
switch)
  sub_has_flag -c -C --create && deny "git switch --create"
  sub_has_inline_short -c -C && deny "git switch --create"
  case "$(first_positional_after_sub)" in
  "" | main | master) : ;; # no target or back-to-main -> allow
  *) deny "git switch <branch>" ;;
  esac
  ;;
checkout)
  sub_has_flag -b -B --orphan && deny "git checkout -b"
  sub_has_inline_short -b -B && deny "git checkout -b"
  case "$(first_positional_after_sub)" in
  "" | main | master) : ;; # no target or back-to-main -> allow
  *) deny "git checkout <branch/path>" ;;
  esac
  ;;
esac

# Nothing matched — allow the command through unchanged.
exit 0

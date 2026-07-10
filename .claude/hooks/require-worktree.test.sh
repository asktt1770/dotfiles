#!/usr/bin/env bash
# Unit tests for the worktree guardrail hooks (Hole 1 + Hole 2 of issue #24).
#
# Builds throwaway git fixtures — a main checkout, one of its worktrees, an
# unrelated repo and a plain non-repo directory, plus a ~/.config-style symlink
# into the main checkout — then feeds hook payloads on stdin and asserts the exit
# code (2 = blocked, 0 = allowed). Mirrors the block/allow case-matrix style of
# block-upstream-writes.sh's verification.
#
# Run: .claude/hooks/require-worktree.test.sh   (exits non-zero if any case fails)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDIT_HOOK="$HERE/require-worktree-edit.sh"
GIT_HOOK="$HERE/require-worktree-git.sh"

# --- fixtures -------------------------------------------------------------

BASE="$(mktemp -d)"
trap 'rm -rf "$BASE"' EXIT

git_quiet() { git -c init.defaultBranch=main -c commit.gpgsign=false -c user.name=t -c user.email=t@t "$@"; }

# Main checkout with one commit, then a worktree hanging off it.
MAIN="$BASE/proj"
mkdir -p "$MAIN/fish"
git_quiet init -q "$MAIN"
printf 'x\n' >"$MAIN/fish/config.fish"
git_quiet -C "$MAIN" add -A
git_quiet -C "$MAIN" commit -qm init
WT="$MAIN/.claude/worktrees/wt"
git_quiet -C "$MAIN" worktree add -q -b feat/wt "$WT" >/dev/null 2>&1
mkdir -p "$WT/fish"

# An unrelated repo (different git-common-dir) and a plain non-repo dir.
OTHER="$BASE/other"
mkdir -p "$OTHER"
git_quiet init -q "$OTHER"
printf 'y\n' >"$OTHER/file.txt"
git_quiet -C "$OTHER" add -A
git_quiet -C "$OTHER" commit -qm init
PLAIN="$BASE/plain"
mkdir -p "$PLAIN"

# ~/.config-style symlink pointing into the main checkout.
mkdir -p "$BASE/config"
ln -s "$MAIN/fish" "$BASE/config/fish"

# Simulate a Claude session running INSIDE the worktree (the recommended mode):
# the project dir is the worktree, but it must still block main-checkout edits.
export CLAUDE_PROJECT_DIR="$WT"

# --- harness --------------------------------------------------------------

PASS=0
FAIL=0

# check <name> <expected-code> <actual-code>
check() {
  if [[ $2 == "$3" ]]; then
    PASS=$((PASS + 1))
    printf '  ok   %-52s (exit %s)\n' "$1" "$3"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL %-52s (want %s, got %s)\n' "$1" "$2" "$3"
  fi
}

# edit_case <name> <expected> <file_path>
edit_case() {
  local code
  printf '{"tool_input":{"file_path":"%s"}}' "$3" | "$EDIT_HOOK" >/dev/null 2>&1
  code=$?
  check "$1" "$2" "$code"
}

# git_case <name> <expected> <command> <cwd>
git_case() {
  local code payload
  payload="$(printf '{"tool_input":{"command":"%s"},"cwd":"%s"}' "$3" "$4")"
  printf '%s' "$payload" | "$GIT_HOOK" >/dev/null 2>&1
  code=$?
  check "$1" "$2" "$code"
}

echo "Hole 1 — require-worktree-edit.sh:"
edit_case "edit in main checkout" 2 "$MAIN/fish/config.fish"
edit_case "edit new file in main checkout" 2 "$MAIN/nvim/init.lua"
edit_case "edit inside a worktree" 0 "$WT/fish/config.fish"
edit_case "edit via ~/.config symlink" 2 "$BASE/config/fish/config.fish"
edit_case "edit in an unrelated repo" 0 "$OTHER/file.txt"
edit_case "edit in a non-repo dir" 0 "$PLAIN/whatever.txt"
edit_case "no file_path" 0 ""

echo "Hole 2 — require-worktree-git.sh:"
git_case "merge in main checkout" 2 "git merge upstream/main" "$MAIN"
git_case "switch -c in main checkout" 2 "git switch -c foo" "$MAIN"
git_case "checkout -b in main checkout" 2 "git checkout -b foo" "$MAIN"
git_case "switch to non-main branch" 2 "git switch feature" "$MAIN"
git_case "checkout non-main branch" 2 "git checkout feature" "$MAIN"
git_case "commit in main checkout" 2 "git commit -m x" "$MAIN"
git_case "rebase in main checkout" 2 "git rebase main" "$MAIN"
git_case "cherry-pick in main checkout" 2 "git cherry-pick abc123" "$MAIN"
git_case "revert in main checkout" 2 "git revert HEAD" "$MAIN"
git_case "reset --hard in main checkout" 2 "git reset --hard HEAD~1" "$MAIN"
git_case "restore in main checkout" 2 "git restore fish/x" "$MAIN"
git_case "stash pop in main checkout" 2 "git stash pop" "$MAIN"
git_case "global -c then merge" 2 "git -c k=v merge x" "$MAIN"
git_case "git -C main from a worktree cwd" 2 "git -C $MAIN merge x" "$WT"
git_case "switch main (return to safe)" 0 "git switch main" "$MAIN"
git_case "checkout main (return to safe)" 0 "git checkout main" "$MAIN"
git_case "switch - (previous)" 0 "git switch -" "$MAIN"
git_case "reset (plain, no tree touch)" 0 "git reset HEAD~1" "$MAIN"
git_case "stash push" 0 "git stash push -m x" "$MAIN"
git_case "status (read-only)" 0 "git status" "$MAIN"
git_case "log (read-only)" 0 "git log --oneline" "$MAIN"
git_case "pull (ff on main)" 0 "git pull" "$MAIN"
git_case "fetch" 0 "git fetch origin" "$MAIN"
git_case "add" 0 "git add -A" "$MAIN"
git_case "worktree add" 0 "git worktree add ../w" "$MAIN"
git_case "merge inside a worktree" 0 "git merge x" "$WT"
git_case "switch -c inside a worktree" 0 "git switch -c foo" "$WT"
git_case "merge in an unrelated repo" 0 "git merge x" "$OTHER"
git_case "non-git command" 0 "rm -rf /tmp/nope" "$MAIN"

echo
printf 'Total: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL == 0 ]]

#!/usr/bin/env bash
# Guard: forbid Edit/Write that lands in the MAIN checkout of this repo.
#
# This repository's dotfiles (fish/, nvim/, …) are live-symlinked into ~/.config
# from the main checkout. Editing a file in the main checkout therefore rewrites
# the user's live environment instantly. All implementation work must happen in
# an isolated git worktree instead (see CLAUDE.md > Worktree Workflow).
#
# Registered as a PreToolUse hook for Edit|Write|MultiEdit|NotebookEdit. The hook
# receives the tool invocation as JSON on stdin; exiting 2 blocks the call and
# feeds the stderr message back to Claude so it knows the edit is disallowed.
#
# Detection is branch-name INDEPENDENT (this is the key fix over the old
# `branch == main` hook, which was trivially bypassed by `git switch -c`):
#   - A worktree's git-dir lives under `<common>/worktrees/<name>`, so a git-dir
#     containing `/worktrees/` means the target is inside a worktree -> allow.
#   - Otherwise the target is a main checkout. We only block it when it belongs
#     to THIS project's repo family, identified by a shared git-common-dir. That
#     comparison is stable whether Claude runs from the main checkout OR from a
#     worktree, so a worktree session that reaches back into the main checkout is
#     blocked too (the `$CLAUDE_PROJECT_DIR == top` shortcut would have missed
#     that case, since in a worktree session those two paths differ).
set -euo pipefail

# Read the hook payload and extract the file the Edit/Write tool wants to touch.
input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"
# No file path (e.g. a tool variant that does not carry one) -> nothing to guard.
[ -z "$fp" ] && exit 0

# The directory the target lives in. `dirname` is pure string manipulation, so
# it works even when the file itself does not exist yet (a fresh Write). We probe
# the repo from this directory; following a ~/.config symlink resolves into the
# real repo, so edits made through the symlink are guarded just the same.
dir="$(dirname "$fp")"

# A brand-new file may sit in a directory that does not exist yet (e.g. Write to
# `<repo>/nvim/init.lua` when `nvim/` is new). Walk up to the nearest EXISTING
# ancestor so `git -C` can still resolve the repo — otherwise the guard would be
# silently bypassed for any new file in a new subdirectory of the main checkout.
while [ -n "$dir" ] && [ "$dir" != "/" ] && [ "$dir" != "." ] && [ ! -d "$dir" ]; do
  dir="$(dirname "$dir")"
done

# Resolve the git-dir of the repo the target belongs to. If the directory is not
# inside any git repository (or does not exist yet), git fails -> allow.
gitdir="$(git -C "$dir" rev-parse --path-format=absolute --git-dir 2>/dev/null)" || exit 0

# Inside a worktree -> allow. Worktree git-dirs live under `<common>/worktrees/`.
case "$gitdir" in */worktrees/*) exit 0 ;; esac

# The target is a main checkout. Scope strictly to THIS project's repo family so
# we never block edits to some unrelated repo. The git-common-dir is shared by a
# repo's main checkout and all of its worktrees, so it uniquely identifies the
# family regardless of whether this Claude session runs from the main checkout or
# from a worktree.
target_common="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0
proj_common="$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0

# Different repo family -> not our main checkout -> allow.
[ "$target_common" = "$proj_common" ] || exit 0

echo "BLOCKED: editing the main checkout is not allowed (its dotfiles are live-symlinked from ~/.config). Create an isolated worktree first with the EnterWorktree tool, then edit inside it. See CLAUDE.md > Worktree Workflow." >&2
exit 2

---
name: start-work
description: Begin a new piece of implementation work in this repo by creating an isolated git worktree + feature branch via the EnterWorktree tool, then working inside it. Use when the user signals they want to start implementing/working (e.g. "作業開始", "start work", "let's implement X", "これ作って"). Do NOT use for consultation or research-only requests.
---

# Start Work

Set up isolated implementation work in this dotfiles repo so nothing lands on
`main` directly. See `CLAUDE.md > Worktree Workflow` for the full policy.

## Steps

1. **Skip if already set up.** If this session is already inside a worktree
   (current branch is a feature branch, or cwd is under `.claude/worktrees/`),
   do not create a new one — go straight to step 4.
2. **Choose a branch name** from the task, using Conventional Commit prefixes:
   `feat/<short-kebab>`, `fix/<short-kebab>`, `docs/…`, `chore/…`, `refactor/…`.
   If the scope or name is unclear, ask the user one short question before
   proceeding.
3. **Create the worktree.** Call the `EnterWorktree` tool with `name` set to the
   chosen branch name. It branches from the latest `origin/main` and switches
   this session into the worktree — no `cd` or restart needed.
4. **Confirm and proceed.** Tell the user the worktree path and branch, then do
   the requested work inside it.

## Reminders while working

- The flake only sees git-tracked files: run `git add -A` before
  `nix run .#build` / `nix flake check`. The `Git tree ... is dirty` warning is
  expected, not an error.
- `nix run .#switch` is the user's job (needs sudo); only one branch's config
  can be live at a time.
- If a separate task surfaces mid-work, capture it with `gh issue create` — do
  not start coding it on the current branch.
- Finish with: push → PR → CI → review → squash merge. Call `ExitWorktree`
  (`remove`) only when the user asks; after a squash merge it asks to confirm
  discard, which is expected.

---
name: create-issue
description: Files a GitHub issue that states its next action, so it can be run later with `/goal`. Use for `/create-issue`, when the user says to park something as an issue ("issueにしといて"), or when separate work surfaces mid-task.
---

# Create Issue

Never ask the user anything, because filing an issue must not interrupt their main task. Infer everything from the conversation; a wrong label is corrected with one word afterwards.

In Claude Code, hand this to a background `Agent` with `subagent_type: "fork"`, because a fork keeps the conversation that explains the issue. Elsewhere, use a native subagent with a self-contained brief. Use the current repository unless the user names another.

## Labels

Add exactly one from each table. Decide the action label top to bottom, and stop at the first match.

| Conversation shows                                                                     | Label               |
| -------------------------------------------------------------------------------------- | ------------------- |
| The user will do it, or it is irreversible, or it needs their login or physical action | `human:todo`        |
| The user stated the approach, and `Done when` and `Depends on` can both be written     | `agent:ready`       |
| Anything else                                                                          | `agent:investigate` |

An approach the assistant suggested and the user did not confirm is not stated, so it stays `agent:investigate`, which can only read.

| Conversation shows                            | Label    |
| --------------------------------------------- | -------- |
| The user called it serious, urgent, or a must | `p:must` |
| Anything else                                 | `p:nice` |

## Body

Write in English. Keep secrets, customer details, and private repository names out, because the issue may be public. Omit sections that do not apply, and use `Decision` for `agent:ready`, `Question` for `agent:investigate`.

```markdown
## Context

Found while syncing upstream in #51. `branchNamePrefix = "ryoppippi"` applies to every repository, and each switch reverts UI changes.

## Decision

Use a fork-only activation step, because upstream's file stays untouched. Rejected: editing upstream's line, because it may conflict on future syncs.

## Basis

Written at: a04c32f0, 2026-11-10
Depends on: nix/modules/home/programs/t3code/default.nix
Assumes: `settings` in the t3code module is still a `let` binding.

## Next action

Owner: agent
Add an activation step that sets `.branchNamePrefix` to the username from `personal.nix`. Open a PR and stop before merging.

## Done when

Either `nix run .#build` passes and the PR is open, or a `Stop if` condition was met and an issue comment says which one.

## Stop if

- Any assumption no longer holds.
- The change needs edits outside the new module and its import.
- The build still fails after 3 attempts.

## Later

Human, after merge: run the switch, then confirm `jq .branchNamePrefix ~/.t3/userdata/settings.json` prints `"asktt1770"`.
```

- `Written at`: `git rev-parse --short origin/HEAD` and today's date. For an issue in another repository, take the commit from `gh api repos/<owner>/<repo>/commits/HEAD --jq '.sha[:8]'` instead.
- `Depends on`: the existing files the plan relies on, including ones it only reads.
- `Next action`: one step and where it stops, with `Owner: agent` or `Owner: human`. Put later steps in `Later`.
- `Done when`: a check that can be run. For `agent:investigate`, name the question the comment must answer. For `human:todo`, the user confirms it is done.

## File it

Write the body to a file in the scratchpad, then run `gh issue create --title <title> --body-file <file> --label <action> --label <priority>`. If a label is missing, run `gh label create <name>` for each of `agent:ready`, `agent:investigate`, `human:todo`, `p:must`, and `p:nice` that does not exist, then retry. For an issue in another repository, pass `--repo <owner/repo>` to both commands.

Report one line in the user's language: `#70 を作成（agent:investigate / p:nice）`.

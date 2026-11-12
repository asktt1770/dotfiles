---
name: create-issue
description: Files a GitHub issue, or adds the next step under one as a sub-issue, so it can be run later with `/goal`. Use for `/create-issue`, when the user says to park something as an issue ("issueにしといて"), or when separate work surfaces mid-task.
---

# Create Issue

Never ask the user anything, because filing an issue must not interrupt their main task. Infer everything from the conversation; a wrong label is corrected with one word afterwards.

In Claude Code, hand this to a background `Agent` with `subagent_type: "fork"`, because a fork keeps the conversation that explains the issue. Elsewhere, use a native subagent with a self-contained brief. Use the current repository unless the user names another, and then pass `--repo <owner/repo>` to every `gh issue` and `gh label` command. `gh api` names the repository in its endpoint instead.

## Only this conversation counts

Base the issue on this conversation and on files checked now. Never take decisions or facts from other issues, because they may reflect an older policy.

Search open issues for the same topic first. For a close match, add `Related: #12 (opened YYYY-MM-DD; may be outdated)` to the body and mention it in the report. Never add to it or merge into it unless the user named it.

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

Write in the language and section style of the repository's recent issues, or its README when it has none, because the people reading the queue work in that language. Write only what the issue needs:

- A reminder: a title and a one-line end condition.
- A side task: what to do and why.
- A problem: what happens, the evidence, the options, and the end condition for the whole issue.

Record a settled approach as `Decision (YYYY-MM-DD): <approach>, because <reason>. Rejected: <option>, because <reason>.` Keep secrets, customer details, and private repository names out, because the issue may be public.

Start the body with the action block. Keep its field names exactly, because the queue rules look them up:

```markdown
**Next action** (Owner: agent): Add an activation step that sets `.branchNamePrefix` to the username from `personal.nix`. Open a PR and stop.
**Done when:** `nix run .#build` passes and the PR is open, or a Stop if condition was met and a comment says which.
**Stop if:** an assumption no longer holds; the change needs edits outside the new module and its import; the build still fails after 3 attempts.
**Basis:** Written at a04c32f0, 2026-11-10. Depends on `nix/modules/home/programs/t3code/default.nix`. Assumes `settings` is still a `let` binding.

---
```

- `Next action`: one step and where it stops, with `Owner: agent` or `Owner: human`.
- `Done when`: a check that can be run. For `agent:investigate`, the question the comment must answer. For `human:todo`, the user confirms it is done.
- `Stop if` and `Basis`: only for `Owner: agent`.
- `Written at`: `git rev-parse --short origin/HEAD` and today's date. For another repository, take the commit from `gh api repos/<owner>/<repo>/commits/HEAD --jq '.sha[:8]'`.
- `Depends on`: the existing files the plan relies on, including ones it only reads.

## Next step under an issue

Only when the user names the issue this continues ("#10 の続きで"):

1. Check `gh issue view <number> --json closedByPullRequestsReferences,parent`. If a PR would close it, do not make it a parent, because merging would close the parent too. Instead, file the step under its parent and record the decision there as in step 3; without a parent, file a new issue with `Follows #10` and record the decision in its body. Skip the remaining steps.
2. If that issue still starts with an action block, remove only the block and its queue label. It becomes the parent; leave the rest of its body unchanged.
3. Append the decision the user just stated to the parent as `Decision (YYYY-MM-DD): ...`, and mark any older decision it replaces `Superseded on YYYY-MM-DD`. The user's words in this conversation win over the parent's text.
4. File the step as a new issue with `--parent <number>`. Its body needs only the action block and what the step needs, because the parent holds the problem.

## File it

Write the body to a file in the scratchpad, then run `gh issue create --title <title> --body-file <file> --label <action> --label <priority>`, adding `--parent <number>` for a sub-issue. Change a parent with `gh issue edit <number> --body-file <file> --remove-label <label>`. If a label is missing, run `gh label create <name>` for each of `agent:ready`, `agent:investigate`, `human:todo`, `p:must`, and `p:nice` that does not exist, then retry.

Report one line in the user's language: `#70 を作成（agent:investigate / p:nice）`, or `#11 を #10 の子として作成（agent:ready / p:nice）`.

---
name: done
description: Judges whether the current session can be closed by finding unfinished work and what the user explicitly committed to. Use for `/done` or when the user asks if anything remains before closing or deleting a session.
---

# Done

Decide whether closing this session would lose anything. Report only what belongs
to this conversation: other sessions run in parallel, and their work must not
appear here.

## 1. Check this conversation

The user runs this when they already feel the session is finished, so report only
what they clearly committed to:

- something the user asked to keep or remember, in any wording
- work the user said they would do later or next, in any wording, that has not happened
- background agents, commands, or scheduled tasks still running, because a resumed session does not restart them

Everything else is not a leftover. In particular, skip:

- proposals and options the user did not take up, because leaving them unanswered means declining them
- questions the assistant asked that the user moved past
- decisions and findings that live only in the conversation, unless the user asked to keep them

Something already recorded in a commit, PR, issue, or document is not a leftover
either.

## 2. Check the work this session touched

Check each repository this conversation edited. Skip this step when it edited none.

- **Worktree or feature branch this session owns:** check the whole branch for uncommitted changes, unpushed commits, the PR state, and CI.
- **Shared branch such as `main`:** report only the paths this conversation changed. Other changes and commits there belong to other sessions.

Never use `git log` on a shared branch to work out what this session did, because
it pulls in parallel work.

## 3. Report

Reply in Japanese using this format, with no account of what was done:

```text
判定: 消してOK
残っていること: なし
次に始めること: なし
根拠: 未コミットなし、PR #64 マージ済み、明示された次の作業なし
```

```text
判定: 残あり
残っていること: PR #64 のCI待ち。「このあとREADMEも直す」が未着手
次に始めること: CI結果を確認し、READMEを直す
根拠: CIが実行中、ユーザーが明示したREADME修正のコミットなし
```

Judge `消してOK` unless step 1 or step 2 found something concrete, and quote the
user's words for anything taken from step 1. If this conversation has been compacted, add
`注意: 圧縮前の会話は要約でしか確認できていません`, because a resumed session
does not reload the summarised messages either.

## 4. Finish

In Claude Code, show the verdict in the cmux sidebar with
`claude-session-status verdict ok` for `消してOK` or
`claude-session-status verdict remaining` for `残あり`. The next prompt clears it,
because that prompt can change the answer. Skip this in other agents: they have
no hook to clear it, so a stale `消してOK` would stay.

- **`消してOK`:** end with `/exit で終了してください`. Do not end the session yourself.
- **`残あり`:** propose where each leftover should go: the PR body for this PR's context, a GitHub issue for separate work. Move it only after the user agrees, then run steps 2 and 3 again.

When the user hands a leftover to a new session, write the handoff note, then have
them ask the new session for its next three steps while this one stays open. Fix
the note here if the answer is wrong.

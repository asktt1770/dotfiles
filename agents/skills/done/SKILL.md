---
name: done
description: Judges whether the current session can be closed by finding its leftovers and conversation-only information. Use for `/done` or when the user asks if anything remains before closing or deleting a session.
---

# Done

Decide whether closing this session would lose anything. Report only what belongs
to this conversation: other sessions run in parallel, and their work must not
appear here.

## 1. Check this conversation

Look for what exists only here:

- decisions, conclusions, and agreed next steps not recorded in a commit, PR, issue, or document
- questions still waiting for an answer
- work someone said would happen later, then dropped
- background agents, commands, or scheduled tasks still running, because a resumed session does not restart them

Something already recorded elsewhere is not a leftover, so link to it rather than
restating it.

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
根拠: 未コミットなし、PR #64 マージ済み、会話のみの決定事項なし
```

```text
判定: 残あり
残っていること: PR #64 のCI待ち。キャッシュ方式の決定が会話にしかない
次に始めること: CI結果を確認し、決定事項をPR本文に追記する
根拠: CIが実行中、PR本文にキャッシュ方式の記載なし
```

Judge `残あり` when in doubt. If this conversation has been compacted, add
`注意: 圧縮前の会話は要約でしか確認できていません`, because a resumed session
does not reload the summarised messages either.

## 4. Finish

- **`消してOK`:** end with `/exit で終了してください`. Do not end the session yourself.
- **`残あり`:** propose where each leftover should go: the PR body for this PR's context, a GitHub issue for separate work. Move it only after the user agrees, then run steps 2 and 3 again.

When the user hands a leftover to a new session, write the handoff note, then have
them ask the new session for its next three steps while this one stays open. Fix
the note here if the answer is wrong.

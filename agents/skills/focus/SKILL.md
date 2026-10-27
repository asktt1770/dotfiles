---
name: focus
description: Marks the main task of the current cmux workspace with an Eisenhower quadrant colour, pin and goal description, chosen by the user in one question screen. Use for `/focus [goal]` or priority declarations such as "マスト", "今日中", "これに集中したい", "最優先".
---

# Focus

The marker lives on the caller's cmux workspace: a colour and pin for the
quadrant, and `ゴール: <goal>` as the first line of the description. It is a
sidebar marker for the user; nothing reads it back during the session.

Importance is the user's call, so do not infer the quadrant — the user picks
it. Outside cmux (`$CMUX_WORKSPACE_ID` unset), say that focus needs cmux and
stop.

## Step 1: Draft goal candidates

Draft two or three one-line goals from the arguments and the conversation.
Keep this quick. Each is an outcome, not an activity ("PR #55 をマージ可能にする",
not "PR を見る"), short enough for the sidebar (about 40 characters). Write them
in the user's language.

## Step 2: Ask once, two questions

One AskUserQuestion call with two single-select questions, no previews and no
"(Recommended)":

1. Quadrant — four options in this order, each described by what it applies:

   | Label    | Description                          |
   | -------- | ------------------------------------ |
   | DO       | 緊急かつ重要: 赤 (#E74C3C)・ピン留め |
   | PLAN     | 重要のみ: 緑 (#2ECC71)               |
   | DELEGATE | 緊急のみ: 黄 (#F1C40F)               |
   | DROP     | どちらでもない: 灰 (#95A5A6)         |

2. Goal — the drafted candidates as options. The user types their own through
   "Other".

## Step 3: Apply

Run one command with the chosen quadrant and goal, quoting the goal:

```bash
claude-focus set DO 'PR #55 をマージ可能にする'
```

It sets the colour and pin state, makes `ゴール: <goal>` the description's first
line while keeping the user's own lines below it, then reads the workspace back
and fails if anything did not take. Report its error rather than retrying by
hand.

## Step 4: Report

One line, for example:

```text
🔴 DO で設定しました（ピン留め）: PR #55 をマージ可能にする
```

Then carry on with whatever else the user asked for in the same message.

To change the goal, the user runs `/focus` again. To finish, `/unfocus`.

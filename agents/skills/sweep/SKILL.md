---
name: sweep
description: Reviews every other cmux workspace in the window and shows which sessions can be closed, running `done` in the unjudged ones on request. Use for `/sweep` or when the user wants to triage open sessions in bulk.
---

# Sweep

Show which sessions in this cmux window can be closed. Outside cmux
(`$CMUX_WORKSPACE_ID` unset), say there is nothing to sweep and stop.

## 1. Collect

Run one command:

```bash
claude-session-status sweep
```

It prints each other workspace as JSON: `ref`, `title`, `state`, `verdict`, `git`,
and `surface`. Other windows are not covered, so say so if the user has any.

## 2. Report

Reply in Japanese with one table per group, leaving out empty groups. Show each
workspace's `title`, and its `git` value when set:

| Group        | Condition                                                                  |
| ------------ | -------------------------------------------------------------------------- |
| `消してOK`   | `verdict` is `消してOK`                                                    |
| `残あり`     | `verdict` is `残あり`                                                      |
| `未判定`     | no `verdict` and `surface` is set                                          |
| `確認できず` | no `verdict` and no `surface`: busy, not Claude Code, or several terminals |

## 3. Ask `未判定` sessions

Each `/done` costs that session a turn, so ask before sending. When the user agrees,
send it to each `未判定` workspace, for example:

```bash
cmux send --workspace workspace:3 --surface surface:7 "/done\n"
```

- Only send to a workspace and surface from the JSON of step 1.
- Never pass `--force`. A failure means someone is typing there or a dialog is open, so report it and move on.
- Do not wait for the results. Tell the user to run `/sweep` again once those sessions finish.

## 4. Finish

Leave closing to the user, so never close a workspace or end a session.

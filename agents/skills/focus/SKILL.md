---
name: focus
description: Marks the main task of the current cmux workspace (Eisenhower quadrant colour, pin, goal description) and guards against off-goal requests. Use for `/focus <goal>` or priority declarations such as "マスト", "今日中", "これに集中したい", "最優先".
---

# Focus

cmux holds the visible marker; Claude Code guards the goal. Importance is the
user's call, so this skill proposes and the user confirms with one click.

The caller's cmux workspace description is the single source of truth for the
goal. A `UserPromptSubmit` hook
(`nix/modules/darwin/programs/claude-code/focus-goal.nu`, enabled by
`claude.focusGuard` in `personal.nix`) reads it before every prompt and, when it
starts with `ゴール:`, injects the goal and the guard rule.
The goal therefore survives `/clear` and new sessions in the same workspace.

Run every `cmux` command without `--workspace`: cmux targets the caller's
workspace by default, which is the one this session runs in. Outside cmux
(`$CMUX_WORKSPACE_ID` unset), say that focus needs cmux and stop.

## Step 1: Infer the quadrant and draft the goal

- Wording: "マスト", "最優先", "絶対" → important; "今日中", "至急", "今すぐ", a
  deadline → urgent. Absence of a signal counts as "not".
- Draft a one-line goal from the arguments and the conversation: an outcome,
  not an activity ("PR #55 をマージ可能にする", not "PR を見る"). Keep it short
  enough for the sidebar, about 40 characters.

## Step 2: Confirm with AskUserQuestion

Always confirm, even when the wording is explicit. One single-select question,
four options — the inferred quadrant first with "(Recommended)" appended, the
other three in matrix order. Write labels and previews in the user's language.
The user edits the goal through "Other".

Each option's `preview` is the matrix with that option's quadrant marked `[*]`,
then what it does, why it was (or was not) recommended, and the drafted goal:

```text
              Urgent       Not urgent
           +------------+------------+
 Important | [*] DO     |    PLAN    |
           +------------+------------+
 Not imp.  |  DELEGATE  |    DROP    |
           +------------+------------+

適用: 色 赤 (#E74C3C) ・ピン留め
理由: 「今日中」「マスト」→ 緊急かつ重要
ゴール: PR #55 をマージ可能にする
```

If the user answers through "Other", treat the text as the new goal line, keep
the recommended quadrant, and apply without asking again.

## Step 3: Apply

| Quadrant                | Colour    | Pin   | Follow-up                                                |
| ----------------------- | --------- | ----- | -------------------------------------------------------- |
| DO (urgent & important) | `#E74C3C` | pin   | —                                                        |
| PLAN (important only)   | `#2ECC71` | unpin | —                                                        |
| DELEGATE (urgent only)  | `#F1C40F` | unpin | Propose a `/goal` condition so it can run unattended     |
| DROP (neither)          | `#95A5A6` | unpin | Suggest parking it as an issue and closing the workspace |

Use these hex values, not cmux's named colours: the named `Amber` is a dark
ochre that does not read as yellow in the sidebar, and `Charcoal` is darker than
the intended grey. Quote them, or the shell treats `#` as the start of a comment.

```bash
cmux workspace-action --action set-color --color '#E74C3C'
cmux workspace-action --action pin
cmux workspace-action --action set-description --description 'ゴール: PR #55 をマージ可能にする'
```

Unpin explicitly for the other quadrants, since re-focusing may move a workspace
out of DO. Keep the `ゴール: ` prefix exact — the hook matches on it.

The goal is the description's first line. Read the current description first
(see the `unfocus` skill for the command) and keep the user's own lines: replace
an existing `ゴール:` line, or put the new one above a description that has none.

Follow-ups are suggestions only:

- DELEGATE: write a checkable `/goal` condition (for example
  `/goal PR #55 の CI が緑になり、レビューコメントに全て返信済み`) for the user to
  paste. Never run `/goal` yourself.
- DROP: offer to park it with the parking rules below. Never close the workspace
  yourself.

Finish with one line naming the goal and the quadrant, then carry on with the
goal.

## Derailment guard

While a goal is set, the hook injects it before every prompt. When a request
does not serve the goal, do not start it and do not refuse it. Ask with
AskUserQuestion:

1. **Park it as an issue** — file it where this place keeps work (below).
2. **Add it to the to-do list** — `cmux todo add '<one-line summary>'`.
3. **Switch the main goal to it** — rerun Steps 1–3 for the new request, then
   start it.

Not off-goal: work that serves the goal (including its prerequisites and
blockers), quick factual questions answered in a sentence or two, follow-ups on
the current answer, and `/focus` / `/unfocus`. When unsure, ask — the question
is one click.

Parking destination for option 1, first match wins:

1. The repository's own CLAUDE.md / AGENTS.md rules for capturing tasks.
2. `gh issue create` when `gh repo view` succeeds. Title the request as a task;
   in the body, state the request, the context needed to pick it up cold, and
   that it was parked while working on the goal.
3. Neither: drop option 1 from the question, leaving the to-do list as the
   parking place.

`cmux todo` belongs to the user. Write to it only when they choose option 2.

After parking, report it in one line (issue URL or to-do text) and return to the
goal.

## Unfocus

Use the `unfocus` skill to clear the marker, which also stops the guard.

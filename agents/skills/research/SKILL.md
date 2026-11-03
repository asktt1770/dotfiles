---
name: research
description: Delegates web research across several sources to Codex, then verifies its report before relaying it. Use when a question needs sources compared, options surveyed, or claims checked — not for a single lookup or for investigating this codebase.
---

# Research

Codex gathers the evidence and this session checks it, because a report gets a real check only from someone who did not write it.

Inside T3 Code, read [references/inside-t3.md](references/inside-t3.md); otherwise read [references/outside-t3.md](references/outside-t3.md).

## Models

- Codex: `luna`. `scripts/codex-model.nu` in the `ask-coding-cli` skill's directory resolves the newest slug of the family, so never pin a version number.

## Scope

Answer a single lookup yourself: one fact from one authoritative source, such as a flag, a release version, or what one page says, needs no brief.

For anything larger, settle the question before writing the brief. Codex follows a brief literally and sees none of this conversation, so intent the brief drops is lost.

1. Work out what the user will do with the answer, what would count as an answer, and the bounds the request implies: platform, version, period, audience.
2. List the plausible readings of the request. Ask the user only when they would send the research somewhere different or change the conclusion, and offer those readings as the options.
3. When one reading is clearly the most plausible, take it without asking and state it in both the brief and the report.
4. Keep the user's own terms in the brief, and do not add a preferred answer or a narrower question than the user asked.

Never put secrets or private repository names in a brief, because it is sent to OpenAI. Describe the public technology instead, and if the question cannot be asked without them, ask the user how to proceed.

Every brief demands citations and asks Codex to report a wrong premise:

```text
We are deciding whether to move our Vitest suite to `bun test`. Which Vitest features used by a typical TypeScript project does `bun test` not support? Cite a URL for every claim, quote exact wording for flags and versions, and list anything you could not open or confirm. If the premise of this question is wrong, say so instead of answering around it. Do not edit files.
```

## Reporting

The report is a set of claims, not evidence. Before relaying it:

- Open every source the conclusion depends on and check that it says what the report claims. Skip citations that would not change the conclusion, and count them as unverified.
- A source you cannot open stays unverified, however convincing Codex's quote looks. Codex can reach sites this session cannot, so this is routine rather than a sign of a bad citation.
- When a source disagrees with the report, follow the source and report the disagreement.
- Check the report against the question from step 1, not just against its citations. Send a follow-up brief when it answered a different question.

Then write for the user rather than restating Codex's report:

- Lead with the conclusion. If it rests on anything unverified, say so in the conclusion itself, not only further down.
- Mark each supporting claim as verified or unverified, with its URL. Never leave the reader to assume that a citation was checked.
- State the reading you took when the request allowed more than one.
- Name the tool and model that did the research, for example "Researched by Codex `gpt-6-luna`; sources checked by Claude Code".

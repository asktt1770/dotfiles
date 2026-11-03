# Research outside T3 Code

Never start the CLI of the agent you are running in. From Codex, give the brief to a native subagent, which already runs `luna`, and verify its report in the main session.

## From Claude Code

Resolve the model first, then pass that slug to Codex. `scripts/codex-model.nu` lives in the `ask-coding-cli` skill's directory:

```sh
<ask-coding-cli-dir>/scripts/codex-model.nu
```

Write the brief to a file so that shell quoting cannot alter it, and read the report from the file `-o` writes:

```sh
codex exec --ephemeral --sandbox read-only -m <slug> -c service_tier=fast \
  -c model_reasoning_effort=medium -o <report-file> - < <brief-file>
```

Keep these as two plain commands. A worktree-isolated session refuses `bash -c`, `fish -lc`, `eval`, and complex one-liners, and also `--skip-git-repo-check`, which only a directory outside a Git repository needs.

The measured behaviour in `references/outside-t3.md` of the `ask-coding-cli` skill applies here, including the `medium` floor for `model_reasoning_effort`. `codex exec --help` carries the rest.

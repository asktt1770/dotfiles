# Dotfiles Repository

asktt1770's personal dotfiles managed via **Nix Flake** (nix-darwin + home-manager).

Forked from [ryoppippi/dotfiles](https://github.com/ryoppippi/dotfiles) and customised for asktt1770's setup. User/machine-specific values are kept in the untracked-upstream `personal.nix` so that syncing upstream stays conflict-free.

## Core Commands

```bash
git add <changed paths> && nix run .#switch  # Apply changes
nix run .#update                             # Update dependencies
nix run .#build                              # Test build
```

Nix flakes only see tracked, staged files, so `git add` is required before
`switch`. Stage the paths you changed — never `git add -A`, `git add .`, or
`git add -u`. That staging is a build prerequisite, not a commit plan.

## Layout Notes

- `personal.nix` is the single source of truth for everything fork-specific: username, GitHub ID, extra Homebrew casks and the full masApps list. `nix/flake/constants.nix` reads the username from it and `nix/modules/darwin/personal.nix` applies the Homebrew parts, so no upstream-tracked file needs editing to personalise this checkout.
- `flake.nix` holds only inputs; the outputs live in `nix/flake/` as flake-parts modules (`constants.nix`, `hosts/`, `apps/`, `formatter.nix`).
- `agents/AGENTS.md` is the single global instruction file for every agent; its sections live in `agents/shared/`. Claude Code reads it as `~/.config/claude/CLAUDE.md` (user-scope memory is only read under that name) and resolves the `@` imports; Codex gets the same file with the fragments concatenated at switch time.
- The root `CLAUDE.md` is a symlink to this file. Upstream dropped its copy and relies on the built-in [`agents-md`](https://github.com/anthropics/claude-code/tree/main/mods/agents-md) plugin to load `AGENTS.md` as project instructions; the symlink keeps the instructions loading here without depending on that plugin being enabled.
- `claude/` is symlinked to `~/.config/claude`, so edits there apply to the running Claude Code without a switch.
- `.claude/` is fork-only: the worktree-enforcing and upstream-write-blocking hooks, their tests, and `settings.json` that wires them up.
- `docs/` is fork-only Japanese personal notes (cheatsheet, maintenance guide). The CI security scan excludes it — see `.github/workflows/nix-build.yaml`.
- Git and Ghostty are declarative under `nix/modules/home/programs/`; Fish and Neovim keep plain config in `fish/` and `nvim/`.
- Per-directory notes live in each directory's `README.md` (`nix/`, `fish/`, `nvim/`, `karabiner/`); read the relevant one before editing there.

## Command Privacy and Secret Handling

- Before running any command, make sure the command text, shell history, process list, terminal output, tool invocation log, and coding-agent transcript will not contain raw secrets.
- Never put raw secrets, tokens, API keys, passwords, private keys, session cookies, or credential-bearing environment variable values directly in command strings.
- Use command substitution, existing credential helpers, or existing variable references instead, such as `$(gh auth token)`, `$(ghtkn get)`, or `$GITHUB_TOKEN`, so terminal history and agent transcripts do not contain the secret value.
- Do not echo, print, log, summarise, commit, or paste secret values. If a raw secret is accidentally exposed, rotate or revoke it; deleting shell history is not sufficient.

## Scripting Language Choice

- **Nushell** — the default for any new script. Use the `nushell` skill.
- **Bun Shell or Python** — needs libraries.
- **Bash** — the environment is not ours: Nix build phases, `writeShellApplication`, bootstrap, git hooks.
- **Fish** — interactive config only (`fish/functions/`, abbreviations, completions), never a new script.

## Git Workflow

- **Main branch**: `main`
- This is a personal dotfiles repo — **committing and pushing directly to `main` is fine**. This is an explicit exception to the global commit skill's main-branch rule. Do NOT open a pull request unless explicitly asked.
- Use **Conventional Commits** with UK English spelling
- Commits are signed with a Secure Enclave-backed SSH key (`nix-secure-enclave-key`)

## GitHub Actions: Bot Workflows Are Disabled

Every `Bot: *` workflow is **disabled via the GitHub API**, not via the workflow
files. Nothing in `.github/workflows/` reflects this, so check with
`gh workflow list --all` before assuming they run.

| Workflow                     | State               |
| ---------------------------- | ------------------- |
| `update-flake-frequent.yaml` | `disabled_manually` |
| `update-flake.yaml`          | `disabled_manually` |
| `auto-rebase.yaml`           | `disabled_manually` |
| `update-overlays.yaml`       | `disabled_manually` |
| `update-node-packages.yaml`  | `disabled_manually` |
| `update-skill-sources.yaml`  | `disabled_manually` |
| `update-nvim-plugins.yaml`   | `disabled_manually` |

They inherit upstream's `RYOPPIPPI_NIX_UPDATER_APP_*` secrets, which this fork
does not have, so every scheduled run failed — `update-flake-*` at startup
(their reusable workflow marks the secrets `required: true`) and the rest at the
`setup-git-bot` step. Disabling them GitHub-side rather than editing the YAML
keeps the `.github/` diff against upstream minimal, so upstream syncs stay
conflict-free.

Dependency freshness is covered by periodic upstream merges (upstream's own bots
keep `flake.lock` current) plus `nix run .#update` / `nix run .#update-ai-tools`
on demand. Only `gh-graph` is fork-only and therefore never updated by upstream.

Reviving them needs three things: a GitHub App with its secrets set on this
fork, `gh workflow enable`, and a fix for the hardcoded
`darwinConfigurations.ryoppippi` build target in `update-overlays.yaml` and
`update-node-packages.yaml` — `nix/flake/hosts/darwin.nix` defines
`darwinConfigurations.${username}`, whose value comes from `personal.nix`.

Note that upstream renaming or adding a workflow file resurfaces it as a new,
active workflow — re-check `gh workflow list --all` after a large sync.

## Worktree Workflow

When starting actual implementation work (not consultation or research), work
inside a dedicated git worktree — never edit files directly on `main`.

- **Start of work**: use the `EnterWorktree` tool to create a worktree + branch
  (it branches from the latest `origin/main`). Do this _before_ making any
  edits, so nothing lands on `main` by accident.
- **Consultation / research only**: stay on `main`; no worktree needed.
- **Parallel task found mid-work**: capture it as a GitHub issue
  (`gh issue create`) from the current session — do not start coding it on the
  current branch. Handle it in a separate worktree/session.
- **Building**: the flake only sees git-tracked files, so stage the paths you
  changed before `nix run .#build` / `nix flake check`. The
  `Git tree ... is dirty` warning is expected, not an error.
- **Applying** (`nix run .#switch`): the user runs this (needs sudo) inside the
  worktree directory. Only one branch's config can be live at a time.
- **Finishing**: push → PR → CI → review → squash merge. Call `ExitWorktree`
  only when the user asks.

## External Skills (agent-skills-nix)

Skills are managed via [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix) in `nix/modules/home/agent-skills.nix`. External skill repositories are pinned in `registry/sources/`, not as flake inputs. Local skills live in `agents/skills/` and are enabled automatically — see the `skill-creator` skill.

### Adding a new external skill

1. Add a pin manifest `registry/sources/my-skill.nix`:
   ```nix
   {
     pin = {
       type = "github";
       owner = "owner";
       repo = "repo";
       branch = "main";
     };

     subdir = "path/to/skills";
     idPrefix = "my-skill";
     filter.maxDepth = 1;
   }
   ```
2. Resolve the pin: `nix run .#skills-sources-lock`
3. Select the skill in `agent-skills.nix` — `skills.explicit.<id>` when it needs
   `packages` or a `transform`, otherwise add its prefixed catalog ID to
   `skills.enable`
4. Run `git add registry/ nix/modules/home/agent-skills.nix && nix run .#switch`

Updating external skills is the same lock-then-switch pair. Editing a manifest
without regenerating the lock fails evaluation, so the two always stay in sync.

## System Info

- **Platform**: aarch64-darwin (Apple Silicon)
- **Shell**: Fish
- **Editor**: Neovim

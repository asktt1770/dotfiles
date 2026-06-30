# Dotfiles Repository

ryoppippi's personal dotfiles managed via **Nix Flake** (nix-darwin + home-manager).

## Quick Reference

See @README.md for full documentation.

## Core Commands

```bash
git add . && nix run .#switch  # Apply changes
nix run .#update               # Update dependencies
nix run .#build                # Test build
```

## Command Privacy and Secret Handling

- Before running any command, make sure the command text, shell history, process list, terminal output, tool invocation log, and coding-agent transcript will not contain raw secrets.
- Never put raw secrets, tokens, API keys, passwords, private keys, session cookies, or credential-bearing environment variable values directly in command strings.
- Use command substitution, existing credential helpers, or existing variable references instead, such as `$(gh auth token)`, `$(ghtkn get)`, or `$GITHUB_TOKEN`, so terminal history and agent transcripts do not contain the secret value.
- Do not echo, print, log, summarise, commit, or paste secret values. If a raw secret is accidentally exposed, rotate or revoke it; deleting shell history is not sufficient.

## Project Structure

```
.
├── flake.nix           # Nix entry point
├── nix/modules/        # Nix configuration modules
│   ├── home/           # Cross-platform (home-manager)
│   ├── darwin/         # macOS (nix-darwin)
│   └── linux/          # Linux
├── fish/               # Fish shell config
├── nvim/               # Neovim config
├── agents/skills/      # Shared AI agent skills (Claude, Codex)
├── claude/             # Claude Code config (user memory)
└── .claude/rules/      # Path-specific rules
```

## Dotfiles Locations

| Config  | Location                                | Notes                            |
| ------- | --------------------------------------- | -------------------------------- |
| Fish    | `fish/`                                 | Modular config in `fish/config/` |
| Neovim  | `nvim/`                                 | Lua-based, uses Lazy.nvim        |
| Git     | `nix/modules/home/programs/git/`        | Declarative via Home Manager     |
| Ghostty | `nix/modules/home/programs/ghostty.nix` | Declarative                      |

## Git Workflow

- **Main branch**: `main`
- **Never push to main directly** - create a PR
- Use **Conventional Commits** with UK English spelling
- Commits are GPG-signed with SSH

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
- **Building**: the flake only sees git-tracked files, so run `git add -A`
  before `nix run .#build` / `nix flake check`. The `Git tree ... is dirty`
  warning is expected, not an error.
- **Applying** (`nix run .#switch`): the user runs this (needs sudo) inside the
  worktree directory. Only one branch's config can be live at a time.
- **Finishing**: push → PR → CI → review → squash merge. Call `ExitWorktree`
  only when the user asks.

## External Skills (agent-skills-nix)

Claude Code skills are managed via [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix).

Configuration: `nix/modules/home/agent-skills.nix`

### Adding a new external skill

1. Add flake input in `flake.nix`:
   ```nix
   my-skill = {
     url = "github:owner/repo";
     flake = false;
   };
   ```
2. Add source in `agent-skills.nix`:
   ```nix
   sources.my-skill = {
     path = my-skill;
     subdir = "path/to/skills";
   };
   ```
3. Enable the skill:
   ```nix
   skills.enable = [ "skill-id" ];
   ```
4. Run `git add . && nix run .#switch`

### Adding a local skill

Create a new skill directory in `agents/skills/` with a `SKILL.md` file, then enable it in `agent-skills.nix`.

### Updating external skills

```bash
nix flake update ast-grep-skill  # Update specific skill
nix run .#switch                  # Apply changes
```

### Current skills

**External:**

- **ast-grep**: [ast-grep/claude-skill](https://github.com/ast-grep/claude-skill)

**Local (in `agents/skills/`):**

- git-commit-crafter
- pr-workflow-manager

## System Info

- **Platform**: aarch64-darwin (Apple Silicon)
- **Shell**: Fish
- **Editor**: Neovim

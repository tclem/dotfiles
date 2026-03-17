# AGENTS.md

Personal dotfiles for tclem (Staff Engineer, GitHub). Manages shell config, editor settings, Homebrew packages, and Copilot agent sandbox setup across macOS and Linux.

## Repo Layout

| Path | What it is |
|---|---|
| `install.sh` | Entry point — detects OS, symlinks configs, sets up git |
| `install-macos.sh` | Homebrew, Brewfile, macOS system defaults |
| `install-ubuntu.sh` | apt packages, Rust toolchain |
| `.zshrc` | Main shell config (symlinked to `~/.zshrc`) |
| `zsh/` | Prompt, functions, completions |
| `tmux.conf` | Tmux config (symlinked to `~/.tmux.conf`) |
| `Brewfile` | Homebrew packages and casks |
| `bin/` | Executable scripts (agent workflows, GitHub log) |
| `copilot/` | Copilot agent config, sandbox Dockerfile, skills, project definitions |
| `script/` | Bootstrap and copilot-sync utilities |
| `gh/` | GitHub CLI aliases |
| `vscode/` | Editor settings and extensions list |
| `divvy/` | Window manager shortcuts |
| `iterm2/` | Terminal theme and preferences |

## Key Scripts

- **`bin/agent`** — Launch a tmux session for Copilot agent work. Modes: default (docker sandbox with worktrees), `-l` (local, no worktrees), `-n` (native, no sandbox). Reads project config from `copilot/projects.conf`.
- **`bin/agent-cleanup`** — Tear down worktrees, tmux session, and docker sandbox after agent work.
- **`bin/gh-log`** — Query GitHub Issues/PRs you're involved with since a given date.
- **`script/copilot-sync`** — Sync copilot config (instructions, agents, skills) between this repo and `~/.copilot`. `install` symlinks, `import` copies new files back, `build` rebuilds the docker sandbox template.

## Copilot Agent Setup

`copilot/projects.conf` defines multi-repo projects in INI format:

```ini
[myproject]
repos=owner/repo owner/other-repo:base-branch
local=true  # optional — skip worktrees
```

`copilot/Dockerfile` builds the `copilot-custom` sandbox template on top of `docker/sandbox-templates:copilot` (Ubuntu + Node/Go/Python/Git/gh/ripgrep/jq). Adds build-essential, cmake, Rust toolchain, and pre-cached Cargo/Go dependencies for Blackbird projects.

`copilot/copilot-instructions.md` contains global agent instructions (symlinked to `~/.copilot/`).

## Making Changes

- **Adding a package**: Edit `Brewfile`, run `brew bundle`.
- **Changing shell config**: Edit `.zshrc` or files in `zsh/`. Changes take effect in new shells.
- **Changing agent instructions**: Edit `copilot/copilot-instructions.md`, run `script/copilot-sync install`.
- **Adding a project**: Add a section to `copilot/projects.conf`.
- **Adding a skill**: Create `copilot/skills/<name>/SKILL.md`, run `script/copilot-sync install`.
- **After any install-level changes**: Re-run `./install.sh` to re-symlink and reconfigure.

Secrets and personal overrides go in `~/.localrc` (not versioned).

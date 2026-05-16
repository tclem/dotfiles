# AGENTS.md

Personal dotfiles for tclem (Staff Engineer, GitHub). Manages shell config, editor settings, Homebrew packages, and Copilot agent setup across macOS and Linux.

## Repo Layout

| Path | What it is |
|---|---|
| `install.sh` | Entry point — detects OS, symlinks configs, sets up git |
| `install-macos.sh` | Homebrew, Brewfile, macOS system defaults |
| `install-ubuntu.sh` | apt packages, Rust toolchain |
| `.zshrc` | Main shell config (symlinked to `~/.zshrc`) |
| `zsh/` | Prompt, functions, completions |
| `tmux.conf` | Tmux config (symlinked to `~/.tmux.conf`) |
| `cargo/config.toml` | Cargo config (symlinked to `~/.cargo/config.toml`) — sccache wrapper, git-fetch-with-cli |
| `Brewfile` | Homebrew packages and casks |
| `bin/` | Executable scripts (agent workflows, GitHub log) |
| `copilot/` | Copilot agent config, skills, project definitions |
| `copilot/skills/<name>/SKILL.md` | User-level Copilot skills symlinked into `~/.copilot/skills/` |
| `script/` | Bootstrap and sync utilities |
| `gh/` | GitHub CLI aliases |
| `vscode/` | Editor settings and extensions list |
| `divvy/` | Window manager shortcuts |
| `iterm2/` | Terminal theme and preferences |
| `ghostty/` | Ghostty terminal config (symlinked to `~/Library/Application Support/com.mitchellh.ghostty/config`) |

## Key Scripts

- **`bin/agent`** — Launch a tmux session for Copilot agent work. Modes: default (worktrees), `-l` (local, no worktrees). Reads project config from `copilot/projects.conf`.
- **`bin/agent-cleanup`** — Tear down worktrees and tmux session after agent work.
- **`bin/gh-log`** — Query GitHub Issues/PRs you're involved with since a given date.
- **`script/sync-copilot`** — Sync copilot config (instructions, agents, skills) between this repo and `~/.copilot`. `install` symlinks, `import` copies new files back.

## Copilot Agent Setup

`copilot/projects.conf` defines multi-repo projects in INI format:

```ini
[myproject]
repos=owner/repo owner/other-repo:base-branch
local=true  # optional — skip worktrees
```

`copilot/copilot-instructions.md` contains global agent instructions (symlinked to `~/.copilot/`).

### Skill source of truth

This repo owns Tim's **user-level** Copilot skills. Add or edit personal skills under `copilot/skills/<name>/SKILL.md`, then run `script/sync-copilot install` to symlink them into `~/.copilot/skills/`.

Keep repo-specific workflows in the repo where they apply. Do not promote one repo's labels, bots, branches, runbooks, dashboards, deployment scripts, app harnesses, or style rules into dotfiles unless they are genuinely useful across repos.

### Skill index

| Skill | Scope | Notes |
|---|---|---|
| `choosing-workflow` | User-level | Router for choosing repo-local skills, dotfiles process skills, or app-native workflows. |
| `authoring-pr` | User-level | Personal PR authoring workflow — create new PRs or rewrite an existing PR's title/body so it matches the final diff, with template handling, review-before-posting, and GitHub Posting Protocol. |
| `copy-editing` | User-level | Minimal copy edits that preserve Tim's voice, quirks, and nonstandard phrasing. |
| `writing-skills` | User-level | Guidance for creating, editing, and reviewing dotfiles Copilot skills. |
| `planning-multi-agent-projects` | User-level, narrow | Durable repo-tracked multi-agent planning PRs only; not normal app plan mode. |
| `delegating-plan-work` | User-level, narrow | Readiness and scope checks before handing off repo-tracked plan phases/todos. |
| `designing-before-coding` | User-level | Lightweight design gate before behavior or architecture changes. |
| `planning-implementation` | User-level | Session-local implementation plans for multi-step work. |
| `debugging-systematically` | User-level | Evidence-first bug, regression, and failure investigation. |
| `testing-before-coding` | User-level | Test/verification-first implementation discipline. |
| `verifying-before-claiming` | User-level | Fresh verification before completion claims. |
| `handling-review-feedback` | User-level | Review feedback triage, fixes, and replies. |
| `merging-base-into-pr` | User-level | Merge a PR's actual base ref (not hardcoded `main`), with stacked-PR conflict resolution and `git rerere`. |
| `investigate-alert` | User-level | General alert/incident investigation using available telemetry and code context. |
| `incident-postmortem` | User-level | General postmortem assembly and repair-item workflow. |
| `updating-dependencies` | User-level | Generic dependency update workflow with per-ecosystem PRs and validation. |
| `searching-github-code` | User-level | When to use `gh blackbird` for lexical, symbol, or semantic code search across one or many GitHub repos. |

Keep project-specific operational, app-runtime, UI, and repo-style skills in their owning repositories. Runtime orchestration such as session execution, subagent dispatch, worktree setup, branch finishing, and PR orchestration should be app behavior rather than dotfiles prompt skills.

## Making Changes

- **Adding a package**: Edit `Brewfile`, run `brew bundle`.
- **Changing shell config**: Edit `.zshrc` or files in `zsh/`. Changes take effect in new shells.
- **Changing agent instructions**: Edit `copilot/copilot-instructions.md`, run `script/sync-copilot install`.
- **Adding a project**: Add a section to `copilot/projects.conf`.
- **Adding a skill**: Create `copilot/skills/<name>/SKILL.md`, keep the description trigger-focused, avoid competing with repo-local skills, then run `script/sync-copilot install`.
- **After any install-level changes**: Re-run `./install.sh` to re-symlink and reconfigure.

Secrets and personal overrides go in `~/.localrc` (not versioned).

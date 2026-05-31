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
| `copilot/templates/<name>/SKILL.md` | Starter skills to copy into other repos (not symlinked) |
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
| `pr-author` | User-level | Personal PR authoring workflow — create new PRs or rewrite an existing PR's title/body so it matches the final diff, with template handling, review-before-posting, and GitHub Posting Protocol. |
| `copy-editor` | User-level | Minimal copy edits that preserve Tim's voice, quirks, and nonstandard phrasing. |
| `skill-author` | User-level | Guidance for creating, editing, and reviewing dotfiles Copilot skills. |
| `planning-multi-agent-projects` | User-level, narrow | Durable repo-tracked multi-agent planning PRs only; not normal app plan mode. |
| `delegating-plan-work` | User-level, narrow | Readiness and scope checks before handing off repo-tracked plan phases/todos. |
| `design-before-coding` | User-level | Lightweight design gate before behavior or architecture changes. |
| `adr-author` | User-level | Writing or amending Architecture Decision Records — filename conventions, header template, status lifecycle, ADR-as-separate-PR rule. |
| `design-doc-author` | User-level | Writing long-form design docs that explain a subsystem's shape, contract, and mechanism — the companion to an ADR's terse decision record. |
| `debug` | User-level | Evidence-first bug, regression, and failure investigation. |
| `fixing-root-causes` | User-level | Rejecting defense-in-depth backstops, fallbacks, and "just in case" layers alongside a real fix. |
| `test-before-coding` | User-level | Test/verification-first implementation discipline. |
| `verify-before-claiming` | User-level | Fresh verification before completion claims. |
| `pr-merge-readiness` | User-level | Get a pull request ready to merge by addressing review threads, CI failures, or conflicts, without performing the merge. |
| `deploy-risk-check` | User-level, fallback | Hunt for revert/rollback-worthy failure modes in a PR diff before it deploys or releases. Repo-local equivalent wins. |
| `pr-review-reply` | User-level | Review feedback triage, fixes, and replies. |
| `pr-update-base-branch` | User-level | Merge a PR's actual base ref (not hardcoded `main`), with stacked-PR conflict resolution and `git rerere`. |
| `alert-investigator` | User-level, fallback | General alert/incident investigation when the repo has no equivalent skill. |
| `incident-postmortem` | User-level, fallback | General postmortem assembly when the repo has no equivalent skill. |
| `deps-update` | User-level, fallback | Generic dependency update workflow when the repo has no equivalent skill. |
| `code-rust` | User-level, fallback | Generic Rust style and discipline when the repo has no `rust-coding-skill` of its own. Template at `copilot/templates/rust-coding-skill/` for new repos. |
| `code-go` | User-level, fallback | Generic Go style and discipline when the repo has no `go-coding-skill` of its own. Template at `copilot/templates/go-coding-skill/` for new repos. |
| `blackbird` | User-level | When to use `gh blackbird` for lexical, symbol, or semantic code search across one or many GitHub repos. |
| `reading-source-code` | User-level | Source-first discipline for unfamiliar or possibly-stale dependency APIs. |
| `deprecating-and-removing` | User-level, fallback | Deprecation and removal workflow for decoupled consumers; lockstep-deployed code skips the ceremony. Repo-local deprecation runbook wins. |
| `thinking-about` | User-level | Capture thoughts into `tclem/notes` and run the daily rollup that re-themes `top-of-mind.md` and prunes resolved/stale entries. |

Keep project-specific operational, app-runtime, UI, and repo-style skills in their owning repositories. Runtime orchestration such as session execution, subagent dispatch, worktree setup, branch finishing, and PR orchestration should be app behavior rather than dotfiles prompt skills.

## Making Changes

- **Adding a package**: Edit `Brewfile`, run `brew bundle`.
- **Changing shell config**: Edit `.zshrc` or files in `zsh/`. Changes take effect in new shells.
- **Changing agent instructions**: Edit `copilot/copilot-instructions.md`, run `script/sync-copilot install`.
- **Adding a project**: Add a section to `copilot/projects.conf`.
- **Adding a skill**: Create `copilot/skills/<name>/SKILL.md`, keep the description trigger-focused, avoid competing with repo-local skills, then run `script/sync-copilot install`.
- **Disabling a skill**: Add `disabled: true` to its frontmatter. `script/sync-copilot install` skips it and prunes the existing symlink. Reversible by removing the line.
- **After any install-level changes**: Re-run `./install.sh` to re-symlink and reconfigure.

Secrets and personal overrides go in `~/.localrc` (not versioned).

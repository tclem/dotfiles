---
name: choosing-workflow
description: Use when deciding which workflow or skill should handle a task, especially when repo-local, dotfiles, process, and app-native workflows may overlap.
---

# Choosing Workflow

Choose the narrowest workflow that fits. Do not load competing skills just because names or triggers are similar.

## Precedence

1. **User request and repo instructions** - direct instructions, `AGENTS.md`, and repo-local conventions win.
2. **Repo-local skills** - use for project-specific code, runbooks, operational workflows, app harnesses, and style rules.
3. **Dotfiles skills** - use for cross-repo personal workflows that Tim wants everywhere.
4. **Process skills** - use dotfiles skills for development discipline: design, planning, debugging, testing, review, verification.
5. **App-native affordances** - prefer built-in session, PR, worktree, review, and orchestration UI when available instead of procedural prompt skills.

## Route away from broad skills

| Situation | Prefer |
|---|---|
| Editing Rust in a repo with a repo-local Rust skill | Repo-local Rust skill |
| Editing Rust with no repo-local Rust skill | Global instructions and repo conventions |
| Working in a repo with app/runtime skills | Repo-local skills and app-native tools |
| Running a project-specific on-call/runbook workflow | Repo-local skill or runbook |
| Deciding how to approach implementation | `designing-before-coding` or `planning-implementation` |
| Investigating a bug or regression | `debugging-systematically` |
| Implementing testable behavior | `testing-before-coding` |
| Claiming work is complete | `verifying-before-claiming` |
| Handling review comments | `handling-review-feedback` |
| Searching code across repos, by symbol, or by concept | `searching-github-code` |
| Creating a broadly useful personal workflow | Dotfiles skill |

## Do not promote

Keep runtime/orchestration procedures out of dotfiles unless they add personal cross-repo judgment. Session execution, subagent dispatch, worktree setup, branch finishing, and PR orchestration belong in the app/runtime layer when available.

Keep project-specific operational knowledge in the project repo. Dotfiles skills should not encode one repo's labels, bots, branches, runbooks, dashboards, or deployment scripts.

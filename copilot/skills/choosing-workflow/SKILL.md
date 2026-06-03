---
name: choosing-workflow
description: Use when deciding which workflow or skill should handle a task, especially when repo-local, dotfiles, process, and app-native workflows may overlap.
---

# Choosing Workflow

Choose the narrowest workflow that fits. Do not load competing skills just because names or triggers are similar.

## Precedence

1. **User request and repo instructions** - direct instructions, `AGENTS.md`, and repo-local conventions win.
2. **Repo-local skills** - use for project-specific code, runbooks, operational workflows, app harnesses, and style rules.
3. **Dotfiles skills** - use for cross-repo personal workflows that the user wants everywhere.
4. **Process skills** - use dotfiles skills for development discipline: design, planning, debugging, testing, review, verification.
5. **App-native affordances** - prefer built-in session, PR, worktree, review, and orchestration UI when available instead of procedural prompt skills.

## What this skill is not

This skill resolves **precedence** when multiple workflows could apply. For the per-trigger "when X happens, load skill Y" index — including discipline, authoring, and PR/shipping workflows — see the Development discipline, Authoring artifacts, and PR & shipping workflows lists in `copilot/copilot-instructions.md`. Don't duplicate those triggers here.

## Do not promote

Keep runtime/orchestration procedures out of dotfiles unless they add personal cross-repo judgment. Session execution, subagent dispatch, worktree setup, branch finishing, and PR orchestration belong in the app/runtime layer when available.

Keep project-specific operational knowledge in the project repo. Dotfiles skills should not encode one repo's labels, bots, branches, runbooks, dashboards, or deployment scripts.

## Fallback skills

Some dotfiles skills exist as **explicit fallbacks** for tasks the user does across many repos but where individual repos may provide a specialized version. When both exist, the repo-local skill always wins — its project-specific rules, runbooks, dashboards, and conventions trump the generic fallback. Use the dotfiles fallback only when no repo skill applies.

| Task | Repo skill if it exists | Otherwise |
|---|---|---|
| Editing Rust | repo's `rust-coding-skill` (or equivalent) | `code-rust` |
| Editing Go | repo's `go-coding-skill` (or equivalent) | `code-go` |
| Investigating an alert or incident | repo's alert/incident skill | `alert-investigator` |
| Writing an incident postmortem | repo's `incident-postmortem` (or equivalent) | `incident-postmortem` |
| Updating dependencies | repo's `update-deps` (or equivalent) | `deps-update` |
| Assessing risk profile of a PR | repo's risk-review, deploy-risk, or release-readiness skill | `pr-risk-check` |
| Deprecating or removing an API, feature, or system | repo's deprecation or release-management skill | `deprecating-and-removing` |

Authoring rule for these skills: their description **must** say "Use when... and the repository has no equivalent skill of its own." That signals fallback role at discovery time even though current tooling can't enumerate other skills to enforce it.

## Skills that should never be mirrored into a repo

A small number of dotfiles skills are pure cross-repo personal workflow — they have no repo-level specialization and should not be copied into any project's `.copilot/skills/` or `.github/skills/`. Doing so causes drift and confuses discovery.

- `blackbird` — purely a personal workflow over `gh blackbird`. If a repo wants users to learn the workflow, link to it from the repo's docs rather than vendoring it.
- `pr-author`, `pr-merge-readiness`, `daily-handoff`, `thinking-about`, `copy-editor`, `delegating-plan-work`, `planning-multi-agent-projects`, `skill-author`, `choosing-workflow` — personal workflow only.

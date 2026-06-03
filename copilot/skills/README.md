# Copilot Skills

This directory contains my user-level Copilot skills, synced into `~/.copilot/skills/` by `script/sync-copilot install`.

For each language-coding fallback skill here (e.g. `code-rust`, `code-go`) there is a sibling **starter template** under `../templates/` (e.g. `rust-coding-skill`, `go-coding-skill`). The fallback skill is opinion-light and applies anywhere; the template is opinion-heavy with project-specific extension stubs and is meant to be copied into individual repos. The two intentionally drift — see `../templates/README.md` for details.

## Status

Run `script/skills-status` to print the latest table, or `script/skills-status --update` to refresh the block below in place. Skills with `disabled: true` in their frontmatter are skipped by `sync-copilot install` and pruned from `~/.copilot/skills/`.

<!-- skills-status:begin -->

| Skill | Status | Trigger |
|---|---|---|
| `adr-author` | ✅ on | Use when proposing or recording a significant technical decision (architecture change, new dependency patte... |
| `alert-investigator` | ✅ on | Use when investigating an alert, monitor, incident, error spike, degraded service, or production anomaly, a... |
| `blackbird` | ✅ on | Use when reaching for `gh blackbird` (Blackbird code search) for cross-repo lexical, symbol, or semantic se... |
| `choosing-workflow` | ✅ on | Use when deciding which workflow or skill should handle a task, especially when repo-local, dotfiles, proce... |
| `code-go` | ✅ on | Use when editing or reviewing Go files (*.go) and the repository has no go-coding-skill of its own |
| `code-rust` | ✅ on | Use when editing or reviewing Rust files (*.rs) and the repository has no rust-coding-skill of its own |
| `copy-editor` | ✅ on | Use when copy editing user-written prose while preserving quirky voice, style, phrasing, and minor imperfec... |
| `daily-handoff` | ✅ on | Use when authoring a daily Slack handoff for the Blackbird team - status-first narrative with indented PR b... |
| `debug` | ✅ on | Use when investigating a bug, failing test, production issue, unexpected behavior, flaky behavior, regressi... |
| `delegating-plan-work` | ✅ on | Use when preparing a repo-tracked multi-agent plan phase or todo for handoff to another agent |
| `deprecating-and-removing` | ✅ on | Use when removing old code, sunsetting a feature, consolidating duplicate implementations, or migrating con... |
| `deps-update` | ✅ on | Use when updating project dependencies, processing Dependabot PRs or alerts, grouping dependency updates, r... |
| `design-before-coding` | ✅ on | Use when creating features, changing behavior, adding components, or making design-affecting implementation... |
| `design-doc-author` | ✅ on | Use when authoring or substantially editing a design doc, architecture doc, or subsystem explanation — the ... |
| `fixing-root-causes` | ✅ on | Use when fixing a bug, regression, or unexpected behavior — especially when tempted to add a defensive laye... |
| `incident-postmortem` | ✅ on | Use when assembling, updating, or reviewing an incident postmortem, and the repository has no postmortem sk... |
| `peer-session-reply` | ✅ on | Use when sending any cross-session message after kickoff (send_session_message, send_chat_message), or deci... |
| `planning-multi-agent-projects` | ✅ on | Use when creating a repo-tracked multi-agent planning PR for a large project, especially when phases, livin... |
| `pr-author` | ✅ on | Use when creating a GitHub pull request, or when updating an existing PR's title or body so it matches what... |
| `pr-merge-readiness` | ✅ on | Use when getting a pull request ready to merge by addressing review threads, CI failures, or conflicts, wit... |
| `pr-review-reply` | ✅ on | Use when receiving PR review comments, code review feedback, suggested changes, or reviewer concerns that m... |
| `pr-risk-check` | ✅ on | Use when assessing the risk profile of a PR — what could break, how blast-radius reaches users, and whether... |
| `pr-update-base-branch` | 🚫 off | Use when merging an updated base branch into a PR branch to resolve drift, especially when the PR may be ch... |
| `reading-source-code` | ✅ on | Use when about to call a library, crate, or framework API you haven't verified, when a dependency's behavio... |
| `skill-author` | ✅ on | Use when creating, editing, splitting, renaming, or reviewing Copilot skills in this dotfiles repo |
| `test-before-coding` | ✅ on | Use when implementing a feature or bugfix where behavior can be specified with tests or another executable ... |
| `thinking-about` | ✅ on | Use when the user wants to capture a thought into their tclem/notes inbox, or when running the daily rollup... |
| `tick-test` | ✅ on | A safe demo automation that mirrors agent-merge's drive-to-done loop on the tick cycle |
| `verify-before-claiming` | ✅ on | Use when about to claim work is complete, fixed, passing, installed, synced, or ready for review |

<!-- skills-status:end -->

## Attribution

Some skill-authoring practices here are adapted from Jesse Vincent's Superpowers project, especially the `writing-skills` skill:

- Source: https://github.com/obra/superpowers/tree/main/skills/writing-skills
- License: MIT
- Copyright: Copyright (c) 2025 Jesse Vincent

Adapted ideas include trigger-focused skill descriptions, keeping skills reusable rather than project-specific, and pressure-testing process skills against likely agent rationalizations. The skills in this repo are rewritten for my dotfiles, Copilot CLI, and the `copilot/skills/<name>/SKILL.md` layout.

The `pr-merge-readiness` skill adapts the merge-readiness framing from GitHub's `agent-merge` app skill:

- Source: https://github.com/github/github-app/blob/main/src-tauri/app-skills/agent-merge/SKILL.md
- License: not declared in repository metadata

Adapted ideas include the reviews/checks/mergeable readiness model, the stop-on-wait-state discipline, and CI workaround pressure tests. Repo-specific helper scripts and automated merge behavior are intentionally omitted.

The `reading-source-code` and `deprecating-and-removing` skills adapt ideas from Addy Osmani's `agent-skills` pack:

- Source: https://github.com/addyosmani/agent-skills
- License: MIT
- Copyright: Copyright (c) 2025 Addy Osmani

`reading-source-code` keeps the version-pinning discipline, the source-over-docs hierarchy, the surface-conflicts-explicitly rule, and the anti-pattern of citing Stack Overflow or training memory. It's reframed around reading the *actual source* (cargo cache, `GOMODCACHE`, gem path, `node_modules`, `gh blackbird`) rather than only official docs, and the "STACK DETECTED" ceremony is dropped.

`deprecating-and-removing` keeps the code-as-liability framing, advisory vs compulsory split, deprecator-owns-migration rule, and removal-as-goal discipline. It's rewritten in this repo's voice as a fallback skill that yields to any repo-local deprecation runbook, with an added Scope section that gates the ceremony to genuinely decoupled consumers.

The `code-go` skill (and matching `go-coding-skill` template) adapts the Go style and discipline rules from `github/blackbird-mw`'s `.github/skills/go-coding-skill/SKILL.md`:

- Source: https://github.com/github/blackbird-mw/blob/main/.github/skills/go-coding-skill/SKILL.md
- License: not declared in repository metadata
- Author: tclem

Adapted ideas include the priority hierarchy, static-message-plus-structured-fields logging discipline, errgroup fan-out with bounded concurrency, "accept interfaces, return concrete structs," and the pure-core/thin-wrapper testing split. The user-level fallback strips blackbird-mw-specific surface (Twirp error codes, CGO/clibs, named logging/telemetry packages, vendoring); the template keeps the shape so other Go repos can fork it and fill in project-specific extension stubs.

## Public repo hygiene

This is a public dotfiles repository. Skill examples and documentation must not mention internal project names, private services, unreleased workflows, or other GitHub-internal details. Use public projects or generic placeholders instead.

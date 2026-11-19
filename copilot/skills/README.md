# Copilot Skills

This directory contains my user-level Copilot skills, synced into `~/.copilot/skills/` by `script/sync-copilot install`.

Starter templates for repo-local skills live under `../templates/`.

## Status

Run `script/skills-status` to print the latest table, or `script/skills-status --update` to refresh the block below in place. Skills with `disabled: true` in their frontmatter are skipped by `sync-copilot install` and pruned from `~/.copilot/skills/`.

<!-- skills-status:begin -->

| Skill | Status | Trigger |
|---|---|---|
| `adr-author` | ✅ on | Use when proposing or recording a significant technical decision (architecture change, new dependency patte... |
| `azure-kusto` | 🚫 off | Use when querying Azure Data Explorer/Kusto clusters or inspecting databases, tables, and schemas |
| `batch-pr-review` | ✅ on | Use when coordinating reviews for many pull requests, especially a stack or batch that needs shared researc... |
| `copy-editor` | ✅ on | Use when copy editing user-written prose while preserving quirky voice, style, phrasing, and minor imperfec... |
| `daily-handoff` | ✅ on | Use when authoring a daily Slack handoff for the Blackbird team - status-first narrative with indented PR b... |
| `dd-pup` | 🚫 off | Use when querying Datadog with Pup, checking Pup authentication safely, or reviewing whether a proposed Pup... |
| `debug` | 🚫 off | Use when investigating a bug, failing test, production issue, unexpected behavior, flaky behavior, regressi... |
| `delegating-plan-work` | ✅ on | Use when handing a repo-tracked multi-agent plan phase or todo to another session or agent |
| `design-before-coding` | 🚫 off | Use when creating features, changing behavior, adding components, or making design-affecting implementation... |
| `design-doc-author` | ✅ on | Use when authoring or substantially editing a design doc, architecture doc, or subsystem explanation — the ... |
| `exp-operations` | ✅ on | Use when inspecting, repairing, starting, advancing, stopping, or reading scorecards for a live Microsoft E... |
| `fixing-root-causes` | ✅ on | Use when fixing a bug, regression, or unexpected behavior — especially when tempted to add a defensive laye... |
| `gws-sheets` | 🚫 off | Use when reading or editing Google Sheets cells through the Google Workspace CLI (gws) |
| `planning-multi-agent-projects` | ✅ on | Use when creating a repo-tracked multi-agent planning PR for a large project, especially when phases, livin... |
| `pr-author` | ✅ on | Use when creating a GitHub pull request, or when updating an existing PR's title or body so it matches what... |
| `pr-review-reply` | ✅ on | Use when receiving PR review comments, code review feedback, suggested changes, or reviewer concerns that m... |
| `pr-risk-check` | ✅ on | Use when assessing the risk profile of a PR — what could break, how blast-radius reaches users, and whether... |
| `reading-source-code` | ✅ on | Use when about to call a library, crate, or framework API you haven't verified, when a dependency's behavio... |
| `refresh-plan` | ✅ on | Use when asked to update or refresh a repo-tracked multi-agent plan, or after work merges, a PR changes sta... |
| `skill-author` | ✅ on | Use when creating, editing, splitting, renaming, or reviewing Copilot skills in this dotfiles repo |
| `thinking-about` | ✅ on | Use when the user wants to capture a thought into their tclem/notes inbox, or when running the daily rollup... |
| `verify-before-claiming` | 🚫 off | Use when about to claim work is complete, fixed, passing, installed, synced, or ready for review |

<!-- skills-status:end -->

## Attribution

Some skill-authoring practices here are adapted from Jesse Vincent's Superpowers project, especially the `writing-skills` skill:

- Source: https://github.com/obra/superpowers/tree/main/skills/writing-skills
- License: MIT
- Copyright: Copyright (c) 2025 Jesse Vincent

Adapted ideas include trigger-focused skill descriptions, keeping skills reusable rather than project-specific, and pressure-testing process skills against likely agent rationalizations. The skills in this repo are rewritten for my dotfiles, Copilot CLI, and the `copilot/skills/<name>/SKILL.md` layout.

The behavioral promotion gate in `skill-author` references the `eval-skill` v1 contract from `tclem/agent-retro`:

- Source: https://github.com/tclem/agent-retro/blob/149fc4430c5066b002442f704b2a124eb1f12a0c/docs/skill-eval-v1.md
- License: not declared in repository metadata

The evaluator workflow remains upstream; the local skill keeps only the promotion contract needed to decide whether an edit may land.

The `reading-source-code` skill adapts ideas from Addy Osmani's `agent-skills` pack:

- Source: https://github.com/addyosmani/agent-skills
- License: MIT
- Copyright: Copyright (c) 2025 Addy Osmani

`reading-source-code` keeps the version-pinning discipline, the source-over-docs hierarchy, the surface-conflicts-explicitly rule, and the anti-pattern of citing Stack Overflow or training memory. It's reframed around reading the *actual source* (cargo cache, `GOMODCACHE`, gem path, `node_modules`, `gh blackbird`) rather than only official docs, and the "STACK DETECTED" ceremony is dropped.

The `dd-pup` skill is informed by the official Datadog Pup skill:

- Source: https://github.com/DataDog/pup/tree/v2.4.1/skills/dd-pup
- License: Apache-2.0

It limits its command guidance to Datadog workflows observed in session history, while documenting verified Pup mappings, partial replacements, unsupported operations, nonprompting authentication checks, and read-only investigations.

The `go-coding-skill` template adapts the Go style and discipline rules from `github/blackbird-mw`'s `.github/skills/go-coding-skill/SKILL.md`:

- Source: https://github.com/github/blackbird-mw/blob/main/.github/skills/go-coding-skill/SKILL.md
- License: not declared in repository metadata
- Author: tclem

Adapted ideas include the priority hierarchy, static-message-plus-structured-fields logging discipline, errgroup fan-out with bounded concurrency, "accept interfaces, return concrete structs," and the pure-core/thin-wrapper testing split. The template keeps the shape so other Go repos can fork it and fill in project-specific extension stubs.

## Public repo hygiene

This is a public dotfiles repository. Skill examples and documentation must not mention internal project names, private services, unreleased workflows, or other GitHub-internal details. Use public projects or generic placeholders instead.

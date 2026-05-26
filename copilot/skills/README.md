# Copilot Skills

This directory contains my user-level Copilot skills, synced into `~/.copilot/skills/` by `script/sync-copilot install`.

## Attribution

Some skill-writing practices here are adapted from Jesse Vincent's Superpowers project, especially the `writing-skills` skill:

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

## Public repo hygiene

This is a public dotfiles repository. Skill examples and documentation must not mention internal project names, private services, unreleased workflows, or other GitHub-internal details. Use public projects or generic placeholders instead.

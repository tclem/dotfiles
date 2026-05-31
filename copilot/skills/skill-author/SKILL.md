---
name: skill-author
description: Use when creating, editing, splitting, renaming, or reviewing Copilot skills in this dotfiles repo.
---

# Authoring Skills

Create small, searchable user-level Copilot skills that encode durable judgment the user wants across repos.

## Core rule

A skill is reusable workflow guidance, not a diary entry and not a substitute for app behavior. It should help a future agent decide **when** to load it and **how** to behave differently after reading it.

## When to create a skill

Create or update a dotfiles skill when the guidance is:

- Personal to the user across many repos.
- Hard to enforce mechanically.
- Easy for agents to forget, rationalize away, or overdo.
- Useful enough that future sessions should discover it without the user repeating themselves.

Do not create a dotfiles skill for:

- Repo-specific labels, branches, dashboards, commands, app harnesses, or runbooks.
- One-off project decisions.
- Runtime orchestration that belongs in the app, such as session creation, branch finishing, subagent dispatch, or PR UI behavior.
- Style rules already documented in the target repo.

## Skill shape

Use this layout unless the skill needs something simpler:

```markdown
---
name: short-hyphen-name
description: Use when concrete triggering condition, symptom, or task applies.
---

# Human Title

One or two sentences with the core idea.

## When to use

Specific triggers and non-triggers.

## Rules

The behavior that must change.

## Common mistakes

Likely agent failure modes and how to avoid them.
```

## Description field

The description is for discovery. Keep it trigger-focused.

- Start with "Use when..."
- Name the situation, symptom, or user intent.
- Do not summarize the whole workflow.
- Do not include repo-specific details unless the skill itself is repo-specific.
- Keep it short enough to scan in a skill list.

Good:

```yaml
description: Use when creating, editing, splitting, renaming, or reviewing Copilot skills in this dotfiles repo.
```

Bad:

```yaml
description: Explains the full process for writing high-quality skills, including testing, directory layout, examples, and review.
```

## YAML safety for the description

Frontmatter is parsed as YAML. Single-quote the `description:` value whenever it contains `: ` (colon-space), a `"`, a leading `> | & * ! % @ \``, or ` #`. Single quotes pass everything through literally; use double quotes only if the value itself contains a single quote.

```yaml
description: 'Use when reading layout. Symptoms: jank, "ResizeObserver loop" warnings.'
```

When a skill fails to load, check this first.

## Keep skills narrow

Prefer several focused skills over one broad policy blob. A future agent should be able to load the smallest applicable skill and not inherit unrelated workflow.

If a new skill overlaps an existing skill, either:

1. Narrow the new skill's trigger.
2. Merge the durable rule into the existing skill.
3. Add routing guidance to `choosing-workflow`.

## Fallback skills

Some user-level skills exist as **explicit fallbacks** for tasks the user does across many repos but where individual repos may provide a specialized version (Rust coding, alert investigation, postmortems, dependency updates). When both layers exist, the repo-local skill always wins.

When creating or editing a user-level skill that could plausibly have a repo-level specialization:

- Phrase the description as `"Use when ... and the repository has no equivalent skill of its own."` This signals fallback intent at discovery time. Current tooling can't enumerate other skills to enforce it, but the phrasing sets the expectation.
- Add the skill to the **Fallback skills** table in `choosing-workflow/SKILL.md`.
- Note in the skill body that a repo-local equivalent, if present, supersedes this one.
- If a starter template would help repos bootstrap their own specialized version, put it under `copilot/templates/<name>/SKILL.md` (not `copilot/skills/`). The template is scaffolding; the user-level skill is the live fallback.

## Skills that should never be mirrored into a repo

Some user-level skills are pure cross-repo personal workflow with no repo-level specialization (e.g. `blackbird`, `pr-author`, `thinking-about`, `daily-handoff`, `copy-editor`, `delegating-plan-work`, `planning-multi-agent-projects`, `skill-author`, `choosing-workflow`). They should not be copied into any project's `.copilot/skills/` or `.github/skills/`.

When authoring one of these, note in the body that the skill is user-level only. The "Skills that should never be mirrored" list in `choosing-workflow/SKILL.md` is the canonical roster.

## Disabling a skill without deleting it

To temporarily suppress a skill from `~/.copilot/skills/` without deleting the source, add `disabled: true` to its frontmatter:

```yaml
---
name: pr-merge-readiness
disabled: true
description: '...'
---
```

`script/sync-copilot install` skips disabled skills and prunes any existing symlink. Remove the line to re-enable. Use this when:

- A skill is in draft and you don't want it discoverable yet.
- A repo-local or app-bundled skill genuinely replaces yours (not the case for `pr-merge-readiness` vs `agent-merge` — those are deliberately distinct: `pr-merge-readiness` drives to green and stops, `agent-merge` keeps going through the merge).
- You want to A/B test removing a skill before deleting it.

Find disabled skills with `script/skills-status` or `rg '^disabled: true' copilot/skills/*/SKILL.md`.

## Pressure-test discipline skills

For skills that enforce discipline, write against the failure mode agents naturally choose under pressure.

Before calling the skill done, ask:

- What temptation is this skill preventing?
- What excuse would an agent use to ignore it?
- Does the skill explicitly close that loophole?
- Is the required behavior concrete enough to follow without guessing?

If the skill can be skipped with "this case is different", "being pragmatic", "I'll do it later", or "the spirit still applies", tighten the rule.

## Attribution

When adapting ideas from another public skill or workflow, add or update `copilot/skills/README.md` with the source, license, and what was adapted. Do not copy large sections verbatim unless the license permits it and attribution is included.

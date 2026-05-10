---
name: writing-skills
description: Use when creating, editing, splitting, renaming, or reviewing Copilot skills in this dotfiles repo.
---

# Writing Skills

Create small, searchable user-level Copilot skills that encode durable judgment Tim wants across repos.

## Core rule

A skill is reusable workflow guidance, not a diary entry and not a substitute for app behavior. It should help a future agent decide **when** to load it and **how** to behave differently after reading it.

## When to create a skill

Create or update a dotfiles skill when the guidance is:

- Personal to Tim across many repos.
- Hard to enforce mechanically.
- Easy for agents to forget, rationalize away, or overdo.
- Useful enough that future sessions should discover it without Tim repeating himself.

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

## Keep skills narrow

Prefer several focused skills over one broad policy blob. A future agent should be able to load the smallest applicable skill and not inherit unrelated workflow.

If a new skill overlaps an existing skill, either:

1. Narrow the new skill's trigger.
2. Merge the durable rule into the existing skill.
3. Add routing guidance to `choosing-workflow`.

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

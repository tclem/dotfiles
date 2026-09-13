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

Use short frontmatter and only necessary sections: a brief core idea, concrete triggers and non-triggers, rules, and common mistakes.

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

Fallback skills cover cross-repo work that repositories may specialize. Repo-local equivalents always win. For each fallback:

- End the description with `"and the repository has no equivalent skill of its own"` and repeat that precedence in the body.
- Add it to the **Fallback skills** table in `choosing-workflow/SKILL.md`.
- Put optional bootstrap guidance under `copilot/templates/<name>/SKILL.md`; the user-level skill remains the live fallback.

## Skills that should never be mirrored into a repo

Pure personal workflow skills should not be copied into a project's `.copilot/skills/` or `.github/skills/`. Mark them user-level only in the body; `choosing-workflow/SKILL.md` owns the canonical roster.

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

Find disabled skills with `script/skills-status`, or grep for `^disabled: true` under `copilot/skills/`.

## Pressure-test discipline skills

For skills that enforce discipline, write against the failure mode agents naturally choose under pressure.

Before calling the skill done, ask:

- What temptation is this skill preventing?
- What excuse would an agent use to ignore it?
- Does the skill explicitly close that loophole?
- Is the required behavior concrete enough to follow without guessing?

If the skill can be skipped with "this case is different", "being pragmatic", "I'll do it later", or "the spirit still applies", tighten the rule.

## Behavioral promotion gate

Behavior-changing edits must pass [`tclem/agent-retro eval-skill`](https://github.com/tclem/agent-retro/blob/main/docs/skill-eval-v1.md); prose review cannot promote them. Freeze target and sentinel cases. Compare baseline and candidate with identical explicit model, effort, trials, and tools. If the candidate grows, add a smaller compressed/ablation candidate. Behavior mode is required; add discovery when description or frontmatter changes. Report failures honestly.

Default: no net growth. Growth requires rationale and measurable target improvement without sentinel/discovery regression; an equivalent shorter variant wins. Remove obsolete/redundant text instead of appending exceptions. Typos, links, formatting, and behavior-neutral metadata require structural validation, not model trials.

Record in the PR body or review artifact: baseline/candidate hashes and sizes; case IDs; model/settings/trials; target/sentinel/discovery results; promotion decision. Omit full/private transcripts.

## Attribution

When adapting ideas from another public skill or workflow, add or update `copilot/skills/README.md` with the source, license, and what was adapted. Do not copy large sections verbatim unless the license permits it and attribution is included.

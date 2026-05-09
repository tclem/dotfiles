---
name: planning-implementation
description: Use when a task spans multiple steps, files, phases, repos, or verification points and needs an implementation plan before editing code.
---

# Planning Implementation

Turn requirements into an executable plan with concrete files, steps, and validation.

## Plan contents

- **Goal:** one sentence describing the outcome.
- **Approach:** the chosen design and why it fits the repo.
- **Files:** exact paths to create, edit, delete, or inspect.
- **Tasks:** ordered, bite-sized steps with dependencies.
- **Validation:** commands or manual checks that prove each meaningful behavior.
- **Risks:** known ambiguity, migration concerns, or follow-up work.

## Guidelines

- Prefer tasks that can be completed and verified independently.
- Put verification before broad implementation when behavior changes.
- Include exact commands when they are known.
- Do not write vague placeholders like "add tests" or "handle errors".
- Keep plans in session state unless the user asks for repo-tracked planning docs. For durable multi-agent project planning PRs, use `planning-multi-agent-projects`.


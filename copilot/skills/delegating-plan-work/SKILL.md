---
name: delegating-plan-work
description: Use when preparing a repo-tracked multi-agent plan phase or todo for handoff to another agent.
---

# Delegating Plan Work

Prepare a focused handoff from a durable multi-agent plan without losing context, breaking dependencies, or turning the prompt into a second plan.

This skill covers readiness and scope judgment, not session orchestration. Use the app's native session/worktree tools for the actual handoff when available.

## When to use

Use this when the user wants an agent to begin, pick up, start, or continue work from a repo-tracked plan created by `planning-multi-agent-projects`, usually under:

```text
docs/copilot/<date>-<project>/
```

Do not use this for normal app plan mode, ad hoc implementation plans, simple delegation that does not reference a repo-tracked phase/todo document, or deciding the mechanics of session creation.

## Before delegating

Read the plan docs first:

1. `README.md` for status, dependencies, parallelism notes, and pre-made agent prompts.
2. `context.md` for shared architecture, decisions, validation commands, and agent guidelines.
3. The target `phase-{NN}-{name}.md` for the specific phase/todos.

Then verify:

- The target phase/todo is unblocked.
- The selected repo and branch/worktree are correct.
- The work can land as its own PR or the prompt clearly says otherwise.
- Validation is concrete enough for the agent to run.
- Parallel agents will not edit the same files or depend on each other's unmerged work.

If dependencies are unclear, stop and ask before handoff.

## Handoff brief

Start from the pre-made prompt in the plan README when one exists. Treat it as the source prompt, then make only the minimal additions needed for the current handoff. If there is no pre-made prompt, keep the brief short and point at the plan docs.

Include:

- Plan location: the plan branch name and PR number, plus the directory path (e.g. `docs/copilot/<date>-<project>/`).
- Explicit fetch instructions, because the child session is on a fresh branch off the base and the plan docs do **not** exist in its worktree. Tell it to read the docs directly from the plan branch via `git`, `gh`, or GitHub MCP tools — for example `gh api repos/<owner>/<repo>/contents/docs/copilot/<dir>/context.md?ref=<plan-branch> -q .content | base64 -d`, or `git fetch origin <plan-branch> && git show origin/<plan-branch>:docs/copilot/<dir>/context.md`. Do not have the child check out, merge, or rebase onto the plan branch.
- Exact files to read (README, context.md, the target phase doc) and the exact phase/todo identifiers.
- Repo and intended worktree/session target, and the base branch the child's PR should target (usually the repo default, **not** the plan branch).
- Current status and dependency assumptions.
- Expected output: code changes, tests, validation, PR, or report.
- Constraints: what not to touch, that plan docs must not be edited from the child session, whether to commit/push.
- Validation commands from the phase doc.
- A requirement to run `/review` with a different frontier model after implementation and before handing work back.
- A short instruction to report changed files, validation results, and blockers.

For parallel work, prepare separate handoffs only for todos called out as parallel-safe or that touch disjoint files with no semantic dependency. For serial work, prepare the next handoff only after the previous result is reviewed.

If the phase doc is missing file paths, validation, or dependencies, update the plan before handoff.

## After the agent reports back

Review the result before updating the plan:

- Did it execute the requested phase/todo and stay in scope?
- Did validation run, and did it prove the intended behavior?
- Did the agent run `/review` with a different frontier model, and address or report any high-confidence findings?
- Are there blockers, discovered bugs, or decisions that belong in `context.md` or the phase doc?
- Is there a PR link or branch that should be added to the plan README?

Only mark work complete after verification and the independent model review. If work is partial, update status as `In progress` or leave it unchanged and record the blocker.

## Common mistakes

- Handing off without the plan branch name and explicit fetch instructions, leaving the child to discover that `docs/copilot/...` doesn't exist on its branch and reverse-engineer how to read it.
- Telling the child to check out, merge, or rebase onto the plan branch instead of fetching plan files read-only.
- Handing off from the README prompt without reading `context.md` and the phase doc yourself.
- Rewriting a pre-made README prompt from scratch instead of using it as the starting point.
- Copying the entire plan into the brief instead of referencing the source docs.
- Starting parallel agents on todos that edit the same files.
- Letting the implementing agent skip the different-model `/review` step before handing work back.
- Letting agents silently update plan docs while implementing code.
- Claiming a phase is complete based only on an agent summary without checking validation.

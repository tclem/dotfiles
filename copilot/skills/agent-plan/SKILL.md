---
name: agent-plan
description: Run the agent plan workflow: research → plan → execute → wrap-up. Use when asked to plan a multi-phase project, create a tracking plan, or coordinate parallel agent sessions.
user-invocable: true
---

# Agent Plan

Create and maintain a structured, multi-phase project plan as markdown documents committed to a branch. The plan lives in the repo — not in session state — so multiple agents (and humans) can read, execute, and update it independently.

This skill produces **documentation, not code**. Each phase becomes a self-contained document with enough context for an agent to execute it without reading the entire plan. Code changes happen in separate PRs linked from the phase docs.

## The deliverable

A directory of markdown files on a dedicated branch:

```
docs/copilot/<date>-<project-name>/
  README.md              # Status dashboard, phase table, roadmap, agent prompts
  context.md             # Architecture, source locations, key decisions, agent guidelines
  phase-{NN}-{name}.md   # One per phase — zero-padded (01, 02, ...), self-contained
  blog-draft.md          # Written near project completion
```

The PR for this branch is documentation-only. It serves as the living tracking hub for the project — updated as phases complete, PRs merge, and scope evolves.

## Workflow

### 1. Research

Before writing anything, deeply understand the problem space. **Interview the user.** Don't accept a vague request — ask pointed questions one at a time using the ask_user tool until you have a crisp understanding of the goal, constraints, and success criteria.

- **Clarify the goal.** What problem are we solving? What does "done" look like? What's explicitly out of scope? Push back if the scope is fuzzy — get it sharp before investing in research.
- **Read the code.** Use explore agents in parallel for large codebases. Trace execution paths. Understand the current architecture.
- **Identify verification strategy.** How will we know each phase works? Are there existing tests to extend? Can we write tests or validation checks *before* the implementation? Not every phase needs tests, but every phase needs a concrete way to verify correctness — whether that's a test suite, a comparison harness, a metric to check, or a manual validation procedure.
- **Map dependencies.** Which changes must come before others? What can be parallelized?
- **Find prior art.** Are there existing patterns in the codebase to follow? Reference implementations?
- **Surface key decisions.** What technical choices need to be made? Document tradeoffs. Don't let decisions stay ambiguous — for each one, grill the user until you get a concrete answer. Present the options, your recommendation, and why. Get a yes or no.

**Decisions that need ADRs:** If a decision is major — it changes architecture, introduces a new dependency pattern, affects public APIs, or would be hard to reverse — propose writing an Architecture Decision Record (ADR). If the repo already uses ADRs (check for `docs/adr/` or similar), follow the existing format and numbering. If not, ask the user whether to create one or document the decision inline in context.md with full rationale. An ADR should be written as a separate PR and reviewed by the team before implementation proceeds.

Confirm your understanding with the user before proceeding. Ask specific questions — don't present a wall of text for approval.

### 2. Create the branch and plan structure

```bash
git checkout -b <user>/<project-name>
mkdir -p docs/copilot/<date>-<project-name>
```

Use the date the project starts (YYYY-MM-DD format).

### 3. Write context.md

This is the shared context that all phase documents reference. An agent starting any phase reads this first. Include:

- **Architecture** — current system overview, ASCII diagrams of request flows or component relationships
- **Key source locations** — exact file paths, function names, line references for the code being changed
- **Key technical decisions** — numbered list of decisions made during research, with rationale. Every decision should be concrete and resolved before implementation starts. For major decisions, link to the ADR (e.g., "See ADR 0067"). For smaller decisions, a one-line rationale here is sufficient.
- **Build & lint commands** — how to validate changes in this repo
- **Agent guidelines** — "read this file first", naming conventions, patterns to follow, things to avoid

Keep it factual and reference-style. This isn't a narrative — it's a lookup document.

### 4. Write phase documents

Each phase is a separate markdown file: `phase-{NN}-{name}.md` (zero-padded: `phase-01-foo.md`, `phase-12-bar.md`). Use zero-padding in filenames for sort order, but refer to "Phase 1", "Phase 12" in prose — no leading zeros in text.

**Structure of a phase document:**

```markdown
# Phase N: Title

> **Status:** 🔲 Not started
>
> Read [context.md](./context.md) first.

**Repo:** `owner/repo`

## Summary

One paragraph: what this phase does and why it matters on its own.

## Key decisions

Decisions specific to this phase (reference context.md for project-wide decisions).

## Todos

### N.0 — Verification setup (when applicable)

If this phase can be test-driven, write the tests or validation harness first.
This todo produces a failing test, comparison script, or metric baseline that
proves the phase isn't done yet — and will prove it is done once implementation
lands. Not every phase needs this (e.g., documentation, config changes), but
any phase that changes behavior should have verification before implementation.

**Files:** `path/to/test_file.rs`

### N.1 — Short title

Description with enough detail to execute. Include:
- What to change and why
- Specific files and functions affected
- Edge cases to watch for
- How this interacts with other code

**Files:** `path/to/file.rs`, `path/to/other.rs`

### N.2 — Short title

...

## Validation

How to verify this phase is complete:
- Specific commands to run (e.g., `cargo test -p crate`, `make lint`, a comparison script)
- Expected outcomes (tests pass, metric matches baseline, no regressions)
- What "done" looks like — observable, not subjective
```

**Phase design principles:**

- Each phase delivers **standalone value** — it can be merged independently
- Phases are ordered by **natural dependencies** — foundational work first
- **Verification first** — when a phase changes behavior, the first todo should be writing a test or validation check that fails before the implementation and passes after. This is the strongest signal that the work is correct.
- Each phase has **numbered sub-todos** (N.1, N.2, ...) with enough detail for an agent to execute without asking clarifying questions
- Include **specific file paths** — agents shouldn't have to search for what to change
- Include **validation criteria** — how to verify the phase is complete

### 5. Write README.md

The README is the status dashboard. Include:

- **One-line summary** of the project
- **Status table** — phase number, description, status (emoji), PR links

```markdown
| Phase | Description | Status |
|-------|-------------|--------|
| [Phase 1](./phase-01-foo.md) | Do the thing | 🔲 Not started |
| [Phase 2](./phase-02-bar.md) | Do the other thing | 🔲 Not started |
```

- **File index** — what each file in the directory is for
- **Roadmap** (optional) — mermaid gantt chart showing phase dependencies and rough sequencing
- **Key decisions** — top-level summary of important technical choices (detail in context.md)
- **Next up** — what to work on now, with enough context to start
- **Parallelism notes** — which phases/todos can run concurrently and which must be serial (see below)
- **Agent prompts** — copy-paste prompts at the bottom (see below)

Status emoji: 🔲 Not started, 🔄 In progress, ✅ Complete, ➡️ Deferred

#### Parallelism

Add a section to the README that explicitly maps out what can run in parallel. Think about:

- **File conflicts** — two todos that modify the same file cannot run in parallel
- **Semantic dependencies** — a todo that introduces a type used by another todo must land first
- **Cross-repo independence** — work in different repos is usually safe to parallelize
- **Sub-todo independence** — within a phase, some sub-todos may touch disjoint files and can run concurrently

Be explicit. Example:

```markdown
## Parallelism

- Phases 1–2 are **serial** — Phase 2 depends on types introduced in Phase 1
- Phases 3 and 4 are **parallel** — Phase 3 touches gateway config, Phase 4 touches Redis (no file overlap)
- Within Phase 6, todos 6.1–6.4 touch different modules and can run in **parallel**
- Phase 8 is **independent** — can run alongside any other phase (different repo)
```

#### Agent prompts

End the README with pre-made prompts — one per todo that's ready for an agent to pick up. These are copy-paste ready: minimal, self-contained, and reference the plan docs so the agent has full context.

```markdown
## Agent prompts

Ready-to-use prompts for spinning up agent sessions. Each prompt targets one todo.
Copy-paste into a new session.

### Phase 1, todo 1.1

> Read `docs/copilot/<date>-<project>/context.md` and
> `docs/copilot/<date>-<project>/phase-01-foo.md`, then execute todo 1.1.

### Phase 1, todo 1.2

> Read `docs/copilot/<date>-<project>/context.md` and
> `docs/copilot/<date>-<project>/phase-01-foo.md`, then execute todo 1.2.
```

**Rules for agent prompts:**

- Keep them minimal — the phase doc and context.md have the detail, not the prompt
- Only list todos that are **currently unblocked** (dependencies met)
- Group parallel-safe todos together with a note: "These can run simultaneously"
- For serial todos, list them in order with a note: "Run in sequence — each depends on the previous"
- Update the prompts section as work completes — remove done todos, unblock new ones

### 6. Commit and open PR

Commit all plan documents to the branch. Open a PR with:
- Title: `[Agent plan] <project name>`
- Body: Summary of the project, phase table with links, key decisions, and a roadmap if applicable

This PR stays open for the life of the project. It's the tracking hub.

### 7. Execute phases

Execution is a separate step — the user (or agents) pick up phases from the plan and execute them as separate PRs. But the plan is a **living document** that this skill also maintains. When you're updating the plan during execution:

- Update phase status in both the phase doc header and the README table
- Add PR links as work merges
- Add a "Supporting PRs" table to the README for related fixes and follow-ups
- Add a "Bugs found" table if issues surface during execution
- Update context.md if new decisions are made or architecture changes
- Update the agent prompts section — remove completed todos, unblock new ones

### 8. Wrap up

When all phases are complete (or deliberately deferred):
- Update the README with final status and any deferred work
- Write a blog post (see below)
- Merge the plan PR to preserve the documentation in the repo

### 9. Write a blog post

As a project nears completion, write a `blog-draft.md` in the plan directory. This captures what was done, why it mattered, what we learned, and what comes next. The draft lives in the repo alongside the plan documents.

The audience depends on the project:
- **Internal discussions post** (most common) — for the team or org, posted to GitHub Discussions or an internal channel
- **Public blog post** (rare) — for the GitHub blog or a personal site, when the work has broad external interest

**Content guidance:**
- Lead with the problem and why it mattered — not the solution
- Be concrete: include before/after metrics, code snippets, architecture diagrams
- Credit the tools and process — if agents did significant work, say so honestly
- Keep it concise. Engineers skim. Use sections, tables, and code blocks.
- End with what's next or what was deferred

Ask the user where the post should be published before writing it.

## Guidelines

- **Be specific.** Vague todos like "refactor the module" are useless. Say exactly what changes, which files, and why.
- **Be honest about scope.** If a phase is too big, split it. If something should be deferred, say so and move it to a "Deferred" section.
- **Living documents.** The plan evolves. Update it as you learn more. Don't let it go stale.
- **No code in plan PRs.** The plan PR is documentation only. Code changes go in separate PRs linked from the phase docs.
- **Context.md is the source of truth** for shared knowledge. Don't duplicate architectural context across phase docs — reference it.
- **Phase docs are self-contained** for execution. An agent should be able to read context.md + one phase doc and have everything it needs.
- **Use ASCII art** for diagrams in markdown — not unicode box-drawing characters.

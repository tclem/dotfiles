---
name: planning-multi-agent-projects
user-invocable: true
description: "Use when creating a repo-tracked multi-agent planning PR for a large project, especially when phases, living docs, parallel workstreams, or a long-running WIP/demo branch with extraction PRs are needed."
---

# Planning Multi-Agent Projects

Create and maintain a structured, multi-phase project plan as markdown documents committed to a branch. The plan lives in the repo — not in session state — so multiple agents (and humans) can read, execute, and update it independently.

This skill produces **documentation, not code**. Each phase becomes a self-contained document with enough context for an agent to execute it without reading the entire plan. Code changes happen in separate PRs linked from the phase docs.

Do not use this for normal app plan mode, single-session implementation plans, or routine code changes. For those, use the app's planning workflow. This skill is only for durable repo-tracked planning hubs.

## The deliverable

A directory of markdown files on a dedicated branch:

```
docs/copilot/<date>-<project-name>/
  README.md              # Status dashboard, phase table, roadmap, delegation preamble
  context.md             # Architecture, source locations, key decisions, agent guidelines
  phase-{NN}-{name}.md   # One per phase — zero-padded (01, 02, ...), self-contained
  blog-draft.md          # Written near project completion
```

The PR for this branch is documentation-only. It serves as the living tracking hub for the project — updated as phases complete, PRs merge, and scope evolves.

## Workflow

### 1. Research

Before writing anything, deeply understand the problem space. **Interview the user.** Don't accept a vague request — ask pointed questions one at a time until you have a crisp understanding of the goal, constraints, and success criteria.

- **Clarify the goal.** What problem are we solving? What does "done" look like? What's explicitly out of scope? Push back if the scope is fuzzy — get it sharp before investing in research.
- **Read the code.** Use explore agents in parallel for large codebases. Trace execution paths. Understand the current architecture.
- **Identify verification strategy.** How will we know each phase works? Are there existing tests to extend? Can we write tests or validation checks *before* the implementation? Not every phase needs tests, but every phase needs a concrete way to verify correctness — whether that's a test suite, a comparison harness, a metric to check, or a manual validation procedure.
- **Map dependencies.** Which changes must come before others? What can be parallelized?
- **Find prior art.** Are there existing patterns in the codebase to follow? Reference implementations?
- **Surface key decisions.** What technical choices need to be made? Document tradeoffs. Don't let decisions stay ambiguous — for each one, grill the user until you get a concrete answer. Present the options, your recommendation, and why. Get a yes or no.

**Decisions that need ADRs:** If a decision is major — it changes architecture, introduces a new dependency pattern, affects public APIs, or would be hard to reverse — load the `adr-author` skill and propose writing an Architecture Decision Record. It covers filename conventions, the standard header, status lifecycle, and the "separate PR before implementation" rule. If the repo doesn't use ADRs at all, ask the user whether to create one or document the decision inline in context.md with full rationale.

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
- **Key technical decisions** — numbered list of decisions made during research, with rationale. Every decision should be concrete and resolved before implementation starts. For major decisions, link to the ADR by filename (e.g. "See `docs/adr/2026-05-16-search-tokenizer.md`"). For smaller decisions, a one-line rationale here is sufficient.
- **Repos and base branches** — one row per repo the project touches, naming the branch PRs actually merge into. This is often *not* the GitHub default: a repo can default to `main` while integrating on `dev`. Handoffs read this to set the child's base, so record it explicitly rather than leaving it to be inferred.

  ```markdown
  | Repo | PRs target |
  |---|---|
  | `owner/service` | `dev` (default branch is `main`) |
  | `owner/client`  | `main` |
  ```

- **Build & lint commands** — how to validate changes in this repo
- **Agent guidelines** — "read this file first", naming conventions, patterns to follow, things to avoid. Always include the no-plan-references rule: every child reads context.md, so stating it here makes it survive a handoff that skipped the preamble. Something like:

  > Nothing you deliver may reference this plan — not code comments, doc comments, test names, commit messages, or PR bodies. These docs live only on the plan branch, so a link to them is dead for reviewers. Justify each change against the code, an ADR, an issue, or a doc on the base branch.

Keep it factual and reference-style. This isn't a narrative — it's a lookup document.

### 4. Write phase documents

Each phase is a separate markdown file: `phase-{NN}-{name}.md` (zero-padded: `phase-01-foo.md`, `phase-12-bar.md`). Use zero-padding in filenames for sort order, but refer to "Phase 1", "Phase 12" in prose — no leading zeros in text.

**Structure of a phase document:**

```markdown
# Phase N: Title

> **Status:** Not started
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
| [Phase 1](./phase-01-foo.md) | Do the thing | Not started |
| [Phase 2](./phase-02-bar.md) | Do the other thing | Not started |
```

- **File index** — what each file in the directory is for
- **Roadmap** (optional) — mermaid gantt chart showing phase dependencies and rough sequencing
- **Key decisions** — top-level summary of important technical choices (detail in context.md)
- **Next up** — what to work on now, with enough context to start
- **Parallelism notes** — which phases/todos can run concurrently and which must be serial (see below)
- **Delegation preamble** — one reusable block for briefing sessions (see below)

Statuses: Not started, In progress, Complete, Deferred

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

#### Delegation preamble

End the README with **one** reusable preamble block — not a prompt per todo. `orchestrate` owns spawning sessions; what it can't know is that your plan docs live on a branch the child won't have. The preamble supplies exactly that, and `## Next` names the work. It's the *opening* of a kickoff prompt — `delegating-plan-work` covers the per-handoff rest (validation commands, constraints, expected output, branch hygiene).

**Critical:** child sessions start on a fresh branch off their *own* repo's base branch, so `docs/copilot/<date>-<project>/` does **not** exist in their worktree. For a phase that lands in a different repo than the plan, `origin` isn't the plan repo at all — so the fetch must name the plan repo explicitly. `gh api` works from anywhere; `git fetch origin <plan-branch>` only works when the child happens to be in the plan repo.

````markdown
## Delegating

Plan docs live only in `<plan-owner>/<plan-repo>`, on this branch. Sessions
spawned for this work start in their target repo, so those docs are not in their
worktree — and for phases in another repo, `origin` is not the plan repo. Every
kickoff prompt for this plan starts with:

> The plan for this work lives in `<plan-owner>/<plan-repo>` on branch
> `<plan-branch>` (PR #NNN), under `docs/copilot/<date>-<project>/`. Those docs
> are **not** in your worktree. Read them read-only — do not check out, merge, or
> rebase onto that branch:
>
> ```
> gh api repos/<plan-owner>/<plan-repo>/contents/docs/copilot/<date>-<project>/context.md?ref=<plan-branch> -q .content | base64 -d
> gh api repos/<plan-owner>/<plan-repo>/contents/docs/copilot/<date>-<project>/phase-<NN>-<name>.md?ref=<plan-branch> -q .content | base64 -d
> ```
>
> Read both, then execute <phase/todo>. Open your PR against `<target-base>` —
> never the plan branch. Do not edit plan docs from your session.
>
> The plan is your context, not the reader's. Nothing you write — code
> comments, doc comments, test names, commit messages, PR body — may mention
> the plan, its phases or todo numbers, this plan PR, or the fact that an
> agent did the work. Those docs aren't on your branch or the base branch, so
> a link to them is dead for every reader. Justify each change on its own
> terms: cite the code, an ADR, an issue, or a permanent doc. If the only
> reason you can give is "the plan says so," you don't yet understand the
> change well enough to land it.

Take `<phase/todo>` from [Next](#next), and the target repo and `<target-base>`
from the phase doc's **Repo:** line and the base-branch table in context.md.
Don't substitute the repo's GitHub default — some repos integrate elsewhere.
````

**Rules:**

- One block, not one per todo. Per-todo prompts duplicate the plan and go stale as work lands.
- Always name the plan repo, plan branch, PR number, and directory. The repo matters: cross-repo phases can't resolve the plan branch through `origin`.
- Never hardcode one base branch, and never assume the repo default. A repo can default to `main` while integrating on `dev` — record each repo's real base in `context.md` and take it from there. The child's PR targets the repo it's working in; never the plan branch.
- **Always carry the no-plan-references rule.** It's the most reliable failure mode in this workflow — see below.
- Keep it minimal: the phase doc and context.md carry the detail, not the prompt.
- `## Next` is what changes as work completes. The preamble should not need touching.

#### Delivered work must stand alone

The child reads the phase doc as its primary context, so it writes as though the reader read it too. The reader didn't, and can't: plan docs live only on the plan branch, and the code PR targets the base branch. **Every plan reference in delivered work is dangling by construction** — reviewers hit a path that isn't in the tree.

It shows up as more than links. Watch for:

- Links or paths to `docs/copilot/...`, or the plan PR number, in a code comment.
- Phase and todo numbers used as identifiers — "Phase 3 requires...", "part of todo 4.2".
- **Plan vocabulary and structure copied into module docs** — a `## Scope` / `Out of scope` block, or a restated requirements list, mirroring the phase doc's shape. This is the subtle one: it reads as thorough documentation while actually being plan residue, and reviewers experience it as oddly formal throat-clearing.
- Root-cause analysis or known-limitation write-ups that belong in an issue.
- Any mention that an agent, session, or plan produced the change.

The repo's own comment standards already forbid most of this; the plan context is what overrides them. So state it as a constraint in the prompt rather than assuming the child's coding guidance will hold.

The test: **would this sentence make sense to someone who will never see the plan?** If not, cut it or re-ground it in something permanent — the code itself, an ADR, an issue, or a doc that lives on the base branch. A phase doc's rationale usually *belongs* somewhere durable; the fix is to put it there, not to link across branches.

State this in both the preamble and context.md's agent guidelines. That isn't redundancy — they reach the child by different paths. The preamble only helps if the coordinator uses it; context.md is read directly by every child, including one spawned from a hand-written prompt.

### 6. Commit and open PR

Commit all plan documents to the branch. Open a PR with:
- Title: `[Agent plan] <project name>`
- Body: **thin and stable** — a one-line summary of the project, a one-line phase status (`Phases 1-2 complete, 3 in progress, 4-8 not started`), and links to the README and any governing ADR. The README is the dashboard; the body points at it. Don't duplicate the phase table here — that's a second copy to drift, and `refresh-plan` keeps the status line current.

This PR stays open for the life of the project. It's the tracking hub.

### 7. Execute phases

Execution is a separate step — the user (or agents) pick up phases from the plan and execute them as separate PRs. That phase-at-a-time sequence is the default; [two-lane execution](#two-lane-execution-wip-and-extraction) is an alternative worth *offering* for large, uncertain features with early demo value.

The plan is a **living document**. Keeping it true as work lands is its own operation — load `refresh-plan` when a PR merges, a session reports back, or the user asks to update the plan. It covers reconciling status against real PR state, updating every surface at once, and leaving the next step obvious.

### 8. Wrap up

When all phases are complete (or deliberately deferred):
- Run a full `refresh-plan` sweep, so every surface — phase headers, README tables, `## Next`, and the PR body — is true at the moment the plan is finalized. Updating the README alone leaves the rest stale in the permanent record.
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

## Two-lane execution: WIP and extraction

Adapted from [the WIP PR pattern](https://adaptivepatchwork.com/2015/01/09/wip/).

An option, not the default. Phase-at-a-time is the normal path; this trades extra coordination for a demoable branch that runs ahead of production code. **Propose it, don't assume it** — it changes how the user reviews and demos work, so it's their call.

It fits when the design is uncertain, someone wants to see the feature working early, the work holds several independently extractable pieces, and mainline moves fast enough that a long-lived branch would rot. Skip it for small or linear changes, and when nobody needs an early demo — a WIP branch nobody looks at is pure overhead.

### The WIP lane

One long-running draft PR per repo the demo touches, with `DO NOT MERGE` in the title. Together they demo as one feature. This is a code PR, separate from the documentation-only plan PR.

- It integrates ideas fast into something buildable and demo-safe. Temporary code, stubs, and shortcuts are fine here.
- Push it early and show it. It may never merge.
- Each WIP feeds a stream of extraction PRs — the ratio is one-to-many, not one-to-one.
- The coordinator owns it: keeps it demo-safe, merges the base branch in regularly, and routes what it learns into extraction prompts and contracts.

### The extraction lane

One fresh session, worktree, branch, and PR per extractable piece, **always based on the repo's real base branch** (`dev`/`main`), never on the WIP branch.

- Extraction sessions independently port *proven behavior*, not prototype history. No cherry-picking or merging from the WIP branch; mainline never depends on it.
- Full quality bar: verification-first tests, correct fundamentals, docs, normal review, CI.
- Extraction PRs are **siblings**, not a stack. WIP branches are integration and demo branches, never stack bases.

### Grow and shrink

As each extraction PR merges, merge the updated base branch into the WIP branch as additive commits, resolve conflicts there, and delete the WIP code the production version replaced.

The WIP diff **grows** during exploration and **shrinks** as production code lands.

### Coordination

- The living plan tracks both lanes: which extraction PRs are open, what the WIP has proven, what's still speculative.
- When the WIP uncovers a bug or API gap, send it to the session that owns that mainline code and record it in the plan. Otherwise stay quiet.
- Cross-repo projects need a WIP PR in each repo the demo touches — together they form one end-to-end prototype, and each carries its own stream of extraction PRs. Share versioned contracts and fixtures rather than restating the same meaning in each repo.

## Guidelines

- **Be specific.** Vague todos like "refactor the module" are useless. Say exactly what changes, which files, and why.
- **Be honest about scope.** If a phase is too big, split it. If something should be deferred, say so and move it to a "Deferred" section.
- **Living documents.** The plan evolves. Update it as you learn more. Don't let it go stale.
- **No code in plan PRs.** The plan PR is documentation only. Code changes go in separate PRs linked from the phase docs — extraction PRs, or a WIP PR.
- **Context.md is the source of truth** for shared knowledge. Don't duplicate architectural context across phase docs — reference it.
- **Phase docs are self-contained** for execution. An agent should be able to read context.md + one phase doc and have everything it needs.
- **Use ASCII art** for diagrams in markdown — not unicode box-drawing characters.

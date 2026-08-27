---
name: refresh-plan
user-invocable: true
description: 'Use when asked to update or refresh a repo-tracked multi-agent plan, or after work merges, a PR changes state, or a child session reports finished.'
---

# Refresh Plan

Reconcile a repo-tracked multi-agent plan with what has actually happened, then leave the next step obvious.

Plans created by `planning-multi-agent-projects` record status in several places at once, and the work itself lands in other repos and other sessions — so the plan is always the last thing to learn about it. This skill is the sweep that closes the gap.

Run it from the plan session, on the plan branch. Child sessions never edit plan docs.

## When to use

- The user asks to update, refresh, or sync the plan.
- A PR merged, changed state, or went stale.
- A child session reported finished.
- Before delegating new work, so the handoff starts from true status.

Not for creating a plan (`planning-multi-agent-projects`), preparing a handoff (`delegating-plan-work`), or normal app plan mode.

## The plan set

"Fully updated" means every one of these agrees:

| Surface | Carries |
|---|---|
| `phase-{NN}-*.md` header | That phase's status and its PR links |
| README status table | Every phase's status — **duplicates the phase headers** |
| README evidence table | Every PR the project depends on, and its state |
| README `## Next` | What to do now |
| README delegation preamble | Branch, PR number, fetch pattern — only when those change |
| `context.md` | Decisions and architecture, only when they changed |
| Auxiliary docs | Findings, benchmarks, corpora — only when superseded |
| Plan PR body | A pointer and one status line — see below |

Status living in both the phase header and the README table is the main drift vector. Update both in the same pass or don't claim the phase.

## Procedure

### 1. Read what the plan claims

Every file in the plan directory, not just the obvious three: README, `context.md`, each phase doc, and the auxiliary docs (findings, benchmarks, corpora). Phase docs hold PR links the README omits, and auxiliary docs hold claims that merged work can supersede. You can't reconcile against a state you haven't read.

### 2. Gather what is true

Collect every PR referenced anywhere in the plan set and query its real state, qualified by repo — these projects routinely span several:

```sh
gh pr view <n> --repo <owner>/<repo> --json state,isDraft,mergedAt,mergeStateStatus,title
```

Then look for work the plan doesn't know about: for each repo the plan names, check merges since the plan's last update against the phase scopes. A user-supplied PR or session report is a starting point, not the whole sweep.

### 3. Reconcile on evidence

Status advances on evidence, never on a report:

- **Complete** — every PR delivering the phase has **merged** *and* the phase doc's validation passed. Both, not either. A phase with no deliverable PR — a decision, an accepted ADR, externally-owned work — says so explicitly in its status line.
- **In progress** — work exists but is open, draft, or partial. An open PR with green validation is still In progress; unmerged work can still change. Some todos landing is not a complete phase.
- **Not started** / **Deferred** — unchanged, or deliberately dropped with a stated reason.

A child session saying "done" is a lead. Check whether the PR merged; `verify-before-claiming` applies to the plan's claims about itself. Carry the evidence inline, as `Complete - [#1234](...)`, so the next reader doesn't re-derive it.

Don't downgrade without evidence either — an unrecorded merge looks like no progress.

### 4. Write the docs

Phase headers, README status table, README evidence table, `context.md` and auxiliary docs where merged work superseded them, and the delegation preamble if the branch or PR number changed. One pass, one commit. `## Next` and the PR body have their own steps below.

### 5. Make the next step obvious

`## Next` is the plan's work queue: a coordinator composes it with the README's delegation preamble to brief a session, so vague entries here become vague kickoff prompts. Rewrite it as an ordered list whose first item is startable right now:

```markdown
## Next

1. **Review and merge the Phase 3 core extraction ([#1234](...))** — unblocks Phases 4 and 5.
2. **Create the two dark-ship flags** — independent, can run alongside.
3. **Toolchain upgrade** — externally owned; tracking only, nothing to do here.
```

Rules:

- Concrete actions, not themes.
- Every item says what it unblocks, or what blocks it.
- Label externally owned items, so nobody waits on the plan for them.
- Delete finished items. A stale next list is worse than none.
- If nothing is startable, say so explicitly and name what everything is waiting on.

### 6. Refresh the PR body

Keep the body thin. It is a pointer to the README, not a second dashboard — a duplicated phase table is one more copy to drift. It carries exactly:

- The one-line summary of what the project does. This describes framing, not progress; rewrite it only when the project's scope or goal actually changed.
- **One status line**, refreshed every sweep: `Phases 1-2 complete, 3 in progress, 4-8 not started.`
- Links to the README and any governing ADR.

Editing it fires the **Pull Request Authoring Gate** — load `pr-author` first — and the **GitHub Posting Protocol**, so the body ends with the required signature block.

One exemption to note while `pr-author` is loaded: its "no process status" rule targets CI results and force-push notes on code PRs. A plan PR is a tracking hub, not a review request, and its phase status line is the point of the artifact. Keep the status line; the rest of `pr-author` still applies.

### 7. Report

Say what advanced, what changed, and what the single next action is. If the sweep turned up something the user needs to decide, ask rather than guessing at a status.

## Common mistakes

- Updating the README table and leaving the phase doc header stale, or the reverse.
- Marking a phase Complete because a session said so, without checking the PR merged.
- Refreshing only the PR that triggered the sweep, leaving the rest of the plan drifting.
- Letting the PR body grow into a copy of the README status table.
- Leaving the PR body's status line stale while the docs are current.
- Leaving finished items in `## Next`.
- Recording a merged PR in the evidence table without advancing the phase it completed.
- Editing plan docs from a child session instead of the plan session.
- Adding scope during a refresh. Reconciling is not replanning — if scope changed, say so and handle it separately.

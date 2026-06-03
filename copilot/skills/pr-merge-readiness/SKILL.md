---
name: pr-merge-readiness
description: Use when getting a pull request ready to merge by addressing review threads, CI failures, or conflicts, or when choosing a merge mode (squash, rebase, merge commit) for a PR — especially stacked PRs whose base is not the repo default branch.
---

# PR Merge Readiness

Drive a PR through every requirement until it is ready to merge, then stop. This skill does the work; it does not press the green button. The user owns the merge.

This is a user-level personal workflow. Do not mirror it into repo-local skills, and do not treat it as a fallback for repo-level auto-merge orchestrations such as `agent-merge`; those run unsupervised and may drive all the way through merge.

## When to use

- The user asks to "get this PR ready to merge," "drive this PR to green," "address the review comments," "fix CI on this PR," or similar.
- A PR has accumulated review threads, CI failures, or conflicts and needs to be unblocked.
- After a rebase or large refactor reopened the review/CI loop.

Do not use this skill to merge. End the turn at "ready to merge."

## Merge conditions

A PR is ready to merge when **all three** are satisfied simultaneously:

| Condition | What it means |
|---|---|
| **Reviews handled** | Every unresolved review thread was addressed on its merits, replied to on GitHub, and resolved. A code change alone does not satisfy this. |
| **CI green** | Required checks passed on the current HEAD. Optional or unrequested checks are informational. |
| **Mergeable** | GitHub reports no conflicts, and the branch is current if branch protection requires it. |

Top-level PR comments and review bodies cannot be resolved on GitHub and are not strict gates. Read them, act on substance, ignore boilerplate.

Work the three conditions **concurrently**, not sequentially. Push code changes early so CI runs against the final state.

## Posture

You are doing the work, not gatekeeping. Address feedback on its merits; `handling-review-feedback` covers review triage and replies. For conflicts and base drift, see `merging-base-into-pr`. For CI failures, see `debugging-systematically` and `fixing-root-causes`. This skill coordinates those workflows and adds the hard stop-before-merge rule.

## Rules

- **Stop at "ready." Do not merge.** Never run `gh pr merge`, the GitHub MCP merge tool, or any equivalent. When all three conditions are green, summarize the state and end the turn. The user merges.
- **End the turn on wait states.** If Reviews and Mergeable are satisfied and only CI is pending, summarize and stop. Do not `sleep`, do not `gh run watch`, do not `gh pr checks --watch`. Blocking inside a tool call locks the user out of interrupting you.
- **No proactive PR comments.** Do not post stand-alone status updates, ping reviewers, or @-mention CODEOWNERS. Reply only when responding to an existing thread or comment.
- **Reviews aren't done until reply + resolve succeeds.** A code change alone doesn't close a thread. Reply on the exact thread and resolve it.
- **Fix CI at the source.** Do not disable shared tooling, skip tests, lower coverage thresholds, remove assertions, mark required checks optional, silence linters, or strip env vars that other PRs rely on. If a CI "fix" hides the failure from future PRs instead of solving it, stop and ask the user.
- **No "temporary" disables or bundle-the-workaround compromises.** They outlive the PR and become permanent regressions no one notices.
- **Always disable pagers** on `gh` commands: `GH_PAGER=""` or pipe to `cat`. Otherwise commands hang in non-interactive shells.
- **Ask the user only for true blockers** — unresolvable conflicts, ambiguous review feedback, persistent CI failures you cannot fix. Not for expected waits like "awaiting human approval."

## Workflow

### 1. Triage

```bash
GH_PAGER="" gh pr view <number> --repo <owner>/<repo> \
  --json state,isDraft,reviewDecision,mergeStateStatus,mergeable,statusCheckRollup
GH_PAGER="" gh pr checks <number> --repo <owner>/<repo>
```

If the PR is already merged or closed, report and stop. Otherwise note which conditions are satisfied and which need work. That is your checklist.

### 2. First pass — push everything actionable now

Work all unsatisfied conditions before entering any wait loop so CI runs against the final state.

- **Conflicts (Mergeable)** — if `mergeable: CONFLICTING`, resolve and push. Use `merging-base-into-pr` for stacked-PR conflict handling against the PR's actual base ref.
- **Branch behind (Mergeable)** — if `mergeStateStatus: BEHIND`, merge base into the PR branch and push.
- **Review threads (Reviews)** — fetch unresolved threads via the GraphQL `reviewThreads` query, then act on each per `handling-review-feedback`. For each thread: make the code change (if any), commit, push, reply on the thread, and resolve. A thread isn't done until reply + resolve succeed.
- **CI failures (Checks)** — pull failed-step logs (`gh run view <run_id> --repo <repo> --log-failed`), identify root cause, and fix at the source per `debugging-systematically` and `fixing-root-causes`.

### 3. Converge

After the first pass, CI is running against the latest push. Don't block on it.

1. Re-check status.
2. If all three conditions are satisfied, go to step 4.
3. If Reviews or Mergeable still need work, keep working them.
4. If **only CI is pending**, summarize and end the turn. The user's next invocation will pick up.
5. After pushing a fix, you may do one immediate re-check with `gh pr checks` to confirm the new run was picked up. Then end the turn.

If the same CI fix has failed twice, or the failure is outside your control, stop and ask the user.

### 4. Ready

When all three conditions are green, verify once and summarize:

```bash
GH_PAGER="" gh pr view <number> --repo <owner>/<repo> \
  --json mergeStateStatus,mergeable,reviewDecision,statusCheckRollup
```

Report:

- Reviews: all threads resolved, with one line on any non-gating feedback you intentionally ignored and why.
- CI: required checks passing.
- Mergeable: `mergeStateStatus: CLEAN` (or `BLOCKED` if waiting on a human approval).

Tell the user the PR is ready to merge. **Stop.** Do not merge.

If `mergeStateStatus` is `BLOCKED` because approval is missing, say so plainly and stop. That is a wait on a human, not something to work around.

## Stacked-PR merge-mode guardrail

This skill bars you from pressing merge. But sometimes the user explicitly authorizes the merge ("merge it", `gh pr merge --auto`, an auto-merge orchestration). Before any merge actually fires — through `gh pr merge`, an app-native merge tool, the GitHub MCP `merge_pull_request` tool, or `curl` against `/pulls/{n}/merge` — run the preflight and pick the right mode.

**Preflight:**

```bash
GH_PAGER="" gh pr view <n> --repo <owner>/<repo> \
  --json baseRefName,baseRepository
```

Compare `baseRefName` to the repo's default branch (`baseRepository.defaultBranchRef.name`, or `gh repo view --json defaultBranchRef`).

**Rule:**

- `baseRefName == default branch` → squash is the house style in many repos; `--squash` is fine when that's the repo's convention.
- `baseRefName != default branch` → the PR is **stacked**. Do **not** squash.
  - Prefer `--rebase` so the child's commits replay cleanly onto the parent.
  - If the child branch has merged the default branch (or its parent) into itself during its work, even `--rebase` can fold the upstream delta back into the parent. In that case, cherry-pick only the child's own commits onto the parent branch by hand and push.

Why this matters: squashing a stacked PR collapses every commit on the child — including any "merge main into branch" commits the child has absorbed — into one commit on the parent. The parent PR's diff balloons with files it had nothing to do with. A real failure of this: `gh pr merge 6303 --squash --auto --delete-branch` on a PR stacked on `tclem/massive-pr-perf-research` produced a single squash of 1,609 files / +287,757 / -48,552 that landed as noise on the parent planning PR.

If you cannot determine the right mode, stop and ask. Do not guess.

## Common mistakes

- **Pressing the merge button.** Even with all three green, the user merges. The skill ends at "ready."
- **Confusing "I made the code change" with "thread handled."** Reply + resolve, or it's not done.
- **Sleeping or watching for CI.** Blocking waits inside a tool call lock the user out. End the turn instead.
- **Status comments on the PR.** Don't post "still working on this" or "@user please review" updates. Stay silent on the PR; talk to the user in chat.
- **Working sequentially.** Don't wait for CI before addressing review threads, or vice versa. Push everything actionable, then converge.
- **Workarounds for CI flakes.** A targeted retry is a fix. Disabling the failing step is not.
- **Treating `reviewDecision: REVIEW_REQUIRED` as defeat.** That's an approval gate; surface it and stop. You don't bypass it.
- **Re-doing finished work.** Review conversation history before re-running expensive steps.

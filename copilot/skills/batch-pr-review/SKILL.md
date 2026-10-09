---
name: batch-pr-review
description: Use when coordinating reviews for many pull requests, especially a stack or batch that needs shared research before individual review sessions.
---

# Coordinating Batch PR Reviews

Coordinate the batch as one review program, not unrelated PR chores. Research shared context once, hand each reviewer the relevant evidence, and keep submission authority narrower than review authority.

This is a user-level personal workflow for a persistent PR Review Coordinator or any app-capable coordinator. The app owns durable conversations, child sessions, workspaces, and review UI; this skill governs how to use those affordances for each batch. Do not mirror it into a repository.

## Intake

Before starting work, inventory the batch:

- PR URL, repository, current head SHA, base, author, draft state, and stack/dependency order.
- Shared domains and related repositories that may establish contracts, history, or invariants.
- Validation cost, risky domains, and likely review depth.
- Requested model diversity, concurrency limit, and review authority policy.

Clarify the batch policy once. Default to staged review comments with no submitted review. Approval submission is a separate authority tier, never an implied consequence of a clean agent report.

## Research before fan-out

Shared research is a hard gate. Start the relevant app-native research sessions first and wait for their findings before opening individual PR review sessions. Do not launch reviewers early with a promise to send context later; first impressions anchor reviews and late context does not reliably repair them.

Synthesize a compact shared-context brief:

- Scope and why the repositories or prior changes matter.
- Cited contracts, source locations, merged changes, and immutable links or commit SHAs.
- Cross-PR invariants, stack order, known hazards, and validation commands.
- Open questions and the exact evidence that remains unavailable.
- Research completion time and the heads or revisions the brief describes.

Keep citations useful to a reviewer; do not paste research transcripts. Every individual session receives the shared brief plus its PR-specific URL, head SHA, base, stack position, review focus, validation expectations, and authority tier.

## Fan-out

Set an explicit concurrency cap before starting reviews. Default to three active review sessions; lower it when validation is expensive, PRs overlap heavily, or the coordinator cannot promptly inspect results. Increase it only when work is independent and supervision remains credible.

When the user requests model diversity, assign at least two frontier model families across the batch. Distribution across the batch is sufficient unless a PR needs a second opinion. Route risky, ambiguous, or representative PRs to the stronger or independent model; do not spend two models on every routine PR by reflex.

Review sessions should inspect the current diff and surrounding code, run bounded validation, and stage comments by default. They report citations, findings, uncertainty, blocked validation, and whether the observed head still matches the assigned SHA.

## Authority tiers

Use the narrowest authority that completes the job:

1. **Stage only - default.** Draft inline comments and a review summary for human inspection. Do not submit.
2. **Submit findings.** Allowed only when the explicit batch policy permits submitting comments or change requests and the coordinator has reconciled the live head and GitHub review state.
3. **Submit approval.** Allowed only under an explicit batch policy for narrowly safe PRs. The PR must have no findings, unresolved questions, model disagreement, blocked validation, stale head, or risky domain; required validation must pass on the current head.

Authentication, authorization, permissions, secrets, data persistence or migration, concurrency, protocol or compatibility changes, generated-code trust boundaries, and broad configuration or rollout changes always require human judgment. So do surprising diffs, uncertain contracts, reviewer disagreement, and evidence that cannot be reproduced.

## Reconcile live state

Child reports are leads, not state. Before submitting anything, asking for a spot check, or producing the final report, read GitHub's current truth:

- Current PR head and whether the reviewed SHA is stale.
- Pending review comments owned by the user.
- Submitted reviews, inline comments, resolved threads, and duplicate drafts.
- Draft/closed/merged state and stack/base changes that invalidate earlier analysis.

If the head changed, do not transplant conclusions onto it. Re-run the affected review or obtain a focused delta review. Never infer pending versus submitted state from session prose or local drafts.

Human steering can happen at any point: spot-check a session, redirect its focus, request a second opinion, or withhold authority. Preserve the evidence and decision boundary when steering so the next reviewer can tell what changed.

## Final report

Link only sessions that require attention:

- Actionable findings or staged comments to inspect.
- Uncertainty, model disagreement, or risky-domain judgment.
- Blocked validation or missing evidence.
- Stale heads, reconciliation conflicts, or an approval decision reserved for the human.

Omit clean, reconciled sessions that need no decision. Give a compact batch count separately if useful; do not make the user open every session to discover that nothing happened.

## Common mistakes

- Starting PR reviews while shared research is still running.
- Sending raw research instead of a compact cited brief.
- Treating one child session's summary as GitHub's live review state.
- Using the same model for the whole batch after model diversity was requested.
- Letting concurrency outrun the coordinator's ability to inspect and steer.
- Submitting comments or approvals when the policy only authorized staging.
- Auto-approving a clean-looking PR with blocked validation, a stale head, or a risky domain.
- Listing every completed session in the final report instead of only attention items.

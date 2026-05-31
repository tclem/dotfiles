---
name: deploy-risk-check
description: Use when reviewing a PR that will deploy or release to users, to hunt for failure modes that could force a revert or rollback, and the repository has no equivalent skill of its own.
---

# Assessing Deploy Risk

Before a PR ships, hunt the diff for changes whose failure mode is "page someone / roll back / restore from backup." Correctness review and deploy-risk review are different lenses — passing tests don't tell you whether the change is safe to roll out.

If the repository has its own deploy-risk, release-readiness, or change-review skill, that wins. Use this skill when nothing more specific applies.

## When to use

- Finishing a PR that auto-deploys on merge, or that ships in the next release.
- Reviewing someone else's PR before approval.
- After a rebase or large refactor that touches production code paths.

Skip for: docs-only changes, test-only changes, internal tooling that can't reach users, prototypes behind unreleased flags.

## Posture

This skill makes you a careful reviewer, not a gatekeeper. Default to advisory: surface findings so the author can decide. Promote something to a true blocker only when you can prove the failure mode — not when you can imagine one.

The cost of a false-positive blocker (slowed delivery, eroded trust in review) is real. So is the cost of a missed real risk. Calibrate by **showing your work**, not by raising the loudness.

## How to assess

Read the diff with these categories in mind. For each hit, write a concrete note: what could break, how it would manifest, what would catch it, and whether the change is safely revertible.

### Data and persistence

- Schema migrations: is it reversible? Does it block on a long lock? Does the old code still work against the new schema (and vice versa) for the full deploy window?
- Writes to existing rows / files / blobs: is there a path that corrupts or partially updates state?
- Cache key changes: does invalidation happen, or do stale entries serve wrong data?
- New required fields, NOT NULL columns, unique constraints: how do existing rows satisfy them?

### Compatibility

- API contract: request/response shape changes, removed fields, changed error codes, changed status codes.
- Wire protocol or serialization format changes between services that don't deploy atomically.
- Client/server version skew during the deploy window — old client + new server, new client + old server.
- Public types, exported functions, config keys, env var names.

### Blast radius

- Is the change behind a flag, ramped, or all-at-once?
- Does it affect every user, a tenant slice, or a single code path?
- Is there a kill switch? Can it be disabled without a deploy?

### Performance and resource use

- New synchronous I/O, network calls, or DB queries in a hot path.
- Loops or recursion over user-controlled input.
- Lock contention, blocking calls inside async code, unbounded channels or queues.
- Memory allocations in tight loops; new large in-memory caches.
- N+1 patterns in newly touched endpoints.

### Concurrency and correctness

- Shared mutable state added without synchronization.
- Race conditions between newly introduced async tasks.
- Reordered operations that previously had implicit ordering.
- Error paths that leave partial state.

### Security and access

- Auth/authz changes: new endpoints, changed permission checks, bypasses.
- New user-controlled input flowing into queries, shell commands, file paths, deserializers.
- Secrets handling: new credentials, new logging of sensitive values.
- Dependency bumps that pull in unreviewed transitive code.

### Observability and recovery

- Will an operator notice if this breaks? Are there logs, metrics, or traces at the failure point?
- New error swallowed or downgraded to debug?
- Rollback plan: revert the commit and redeploy? Or does data shape lock it in?

## Reporting

Default tone is advisory. Group findings by severity, and let the evidence — not the label — do the work.

- **Blocker** — would force a revert if shipped. Requires proof: cite the diff lines, the existing code that breaks, the doc/RFC/postmortem that establishes the constraint, or the test that fails. If you can't prove it at this bar, it's not a Blocker.
- **Risk** — plausible failure mode with a concrete path. Cite at least: the diff line and the specific scenario that hits it. Recommend a mitigation, flag, or owner ack.
- **Watch** — low likelihood or low impact, but worth a mention. One sentence; no demand attached.

For each item: one-line description, one-line "how it fails in prod" with file:line evidence, one-line suggested mitigation. No essays. If a finding requires deeper research to substantiate, do that research before posting — read the surrounding code, check related modules, search for prior incidents or ADRs, run the migration plan, look at the deploy pipeline config. Show that work in the finding.

If the diff is genuinely low-risk, say so plainly — "no deploy-risk findings; data path unchanged, behind existing flag" beats a manufactured concern. Do not pad the list.

## Common mistakes

- **Acting as a blocker by default.** Findings are advisory unless proven. Loud labels don't compensate for thin evidence.
- **Speculation without proof.** "This *could* race" is not a finding. Show the concurrent writers, the shared state, the missing lock. If you can't, drop it.
- **Rubber-stamping.** "LGTM, no concerns" without naming what was checked. Always name the categories that applied and the ones that didn't.
- **Style nits dressed up as risk.** Formatting, naming, and minor refactors don't belong in a deploy-risk review.
- **Inventing risks.** If you can't describe a concrete failure path with citations, drop the finding.
- **Missing the deploy window.** Old code keeps running during rollout — N-1 compatibility matters even for "internal" changes.
- **Trusting the PR description.** Re-derive risk from the diff. The author's framing is a starting point, not the answer.
- **Skipping migration review** because "the framework handles it." Read the generated SQL or migration plan.
- **"CI will catch it."** CI catches what its tests cover. Deploy-risk categories — N-1 compat, migration locks, blast radius, observability gaps — usually have no test. Walk them anyway.
- **Conflating correctness review with risk review.** "I already reviewed this for correctness" is not the same lens. A correct change can still be unsafe to deploy.

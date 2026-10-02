---
name: exp-operations
description: Use when inspecting, repairing, starting, advancing, stopping, or reading scorecards for a live Microsoft ExP experiment.
---

# ExP Operations

Manage live Microsoft ExP state from current evidence. This is user-level only; never mirror it into a repository. Repo-local experiment skills own checked-in definitions, and `learning-machine-experiment` owns issue/project updates.

## Read before acting

- Browser access is optional. Use an Azure CLI token for `https://exp.azure.net` with the ExP REST API; never print or persist it.
- Management operations currently use `2025-10-01-preview`. Re-verify it with one bounded GET of the exact endpoint or current first-party guidance; endpoint families can differ. Stop if the read or response shape is unexpected.
- Resolve the exact workspace, issue/display name, feature, progression, experiment, step, variants, semantic arm values, gates, active state, and object `eTag`. Match apply reports by issue/display name, never array position.
- IDs must come from the current live response. Never reuse another feature's IDs or expose tracking IDs/raw assignment context.

## Mutate fail-closed

Structure repair, Start, Advance, and Stop are separate operations requiring approval for that exact mutation. Approval to repair never approves Start.

Immediately before a mutation, GET again and assert the expected object `eTag`, steps/order, variants and arm values, allocations, gates, and active/stopped state. Stop on ambiguity, a changed `eTag`, an unexpected active step/count, or any mismatch.

For structure repair, preserve the full GET payload and object `eTag`, change only the approved field, PUT the exact experiment, and re-read it. Canonical Teamship validation has stopped Treatment `0/100` then Control `100/0`; never start it during repair. ExP has returned the concurrency value only in the payload, while an `If-Match` header built from it returned 412, so follow the verified GET/PUT body contract rather than inventing a header.

After Start, Advance, or Stop, re-read and verify the exact active step, stopped timestamps, order, variants, allocations, and gates. Never report success from the mutation response alone.

## Verify and read scorecards

- Validate semantic arm values, audience/version gates, and that unrelated stages remain stopped.
- Released clients cache assignments; verify treatment/control with fresh sessions or processes after propagation.
- Resolve a scorecard to the exact experiment step and variants. Verify status/window: queued, NotStarted, Running, or Processing is not complete.
- Treat 10/10 StaffShip as a smoke/guardrail read unless sample size supports more. Check assignment balance, attribution, reliability, latency, cost, data-power warnings, and the declared outcome metric.
- Never poll, `sleep`, block on watches, or claim queued automation, propagation, issue updates, or scorecard availability completed. Make one bounded read, attach session automation, or report the wait state.

Report the human-readable target, operation, checked preconditions, and verified postcondition. Include IDs only when needed for disambiguation or a canonical link.

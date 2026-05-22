---
name: fixing-root-causes
description: Use when fixing a bug, regression, or unexpected behavior — especially when tempted to add a defensive layer, fallback, retry, "just in case" check, or belt-and-suspenders second fix alongside the real one.
---

# Fixing Root Causes

Solve the root cause once. Do not stack defensive backstops on top of a real fix.

A defense-in-depth fix on top of a root-cause fix is two fixes — one that works and one that hides the next bug. The defensive layer accumulates, drifts from the real invariant, and costs more over time than it saves. The fact that you *can* construct a scenario where the backstop would help is not a reason to add it; almost every line of code has such a scenario.

## When to use

Load this skill when you're about to:

- Add a "just in case" check, fallback, retry, default value, or sentinel around a fix that already solves the actual bug.
- Mix extra inputs into a hash, key, ID, or token because "two things could theoretically collide."
- Add a brand-casing map, display-name override, or hardcoded translation for data that should be correct upstream.
- Wrap a call site in `try`/`catch` / `unwrap_or_default` / `Result::ok()` around something that shouldn't fail.
- Add a second fix in the same PR as the real fix because "while I'm here."
- Write a regression test that pins behavior of the defensive layer rather than the real invariant.

Don't load it for:

- Genuine layered architecture (auth + authz + input validation are not "defense in depth" — they're separate concerns each enforcing their own invariant).
- Real fallbacks where the upstream is genuinely unreliable (network, third-party API, OS calls).
- Backwards-compatibility shims with a known sunset.

## Rules

### 1. Identify the single root cause before writing any code

Before opening an editor, name the *one* place where the invariant was violated. If you can't name it in one sentence, you don't understand the bug yet — keep investigating. Tracing the producer/schema/type path is almost always faster than guessing.

### 2. If the fix needs a fallback, that's a signal, not a feature

A fix that requires a fallback, default, retry, or special-case lookup to "be safe" usually means you fixed the wrong layer. Stop. Trace the producer/schema/type path. The default is the root-cause fix, even when it touches more files.

### 3. Reject the "two plausible fixes" framing — and if both are real, say so out loud

If you find yourself thinking "I'll do A *and* B to be safe," that's the failure mode. Pick A — the root-cause fix. Drop B.

If A and B are genuinely both root-cause fixes for *different* invariants (not the same bug viewed twice), say so explicitly in the PR: "A fixes <invariant 1> across X/Y/Z; B fixes the separate problem that <invariant 2>." Recommend A alone unless the user explicitly chooses to include B.

### 4. Pressure-test every defensive layer with these questions

Before adding any defensive layer, answer concretely:

- **What invariant does this enforce that A doesn't already enforce?** If the answer is "same invariant, different layer," delete it.
- **What test would fail without this layer?** If the answer is "a contrived scenario that doesn't reproduce in the actual system," delete it.
- **What's the cost when this layer drifts from reality?** Defensive layers rot the fastest because no one exercises them. Drift is guaranteed.

If you can't answer all three crisply, the layer doesn't earn its place.

### 5. Don't justify defense-in-depth with a contrived scenario

"In theory, with X and Y and Z and W aligned, this could collide / fail / produce wrong output" is not a reason to add a backstop. Almost any code can be made to fail under enough contortion. If the scenario isn't reachable from the actual system, it doesn't deserve code.

When you catch yourself writing "for a worktree workspace whose base ref resolves so..." or "if the upstream defaults to X when Y is missing, then..." stop. That's a sign you're rationalizing a band-aid. Either fix the producer so the scenario isn't reachable, or accept that the scenario isn't reachable and skip the backstop.

### 6. Tests pin invariants, not safety nets

A regression test should fail when the *real* invariant is violated, not when a defensive layer is removed. If your test exists only to lock in the backstop ("assert that mode is mixed into the token"), it tests the implementation of the backstop, not the underlying behavior. The next agent will delete the layer and the test together because both look unmotivated.

Pin the user-observable behavior instead ("rendering mode X then mode Y produces the correct rows"). That test fails for the right reason if the root cause regresses, and doesn't care which layer enforced the invariant.

### 7. Surface the decision in the PR

When you've made a root-cause fix and decided *not* to add a defensive layer that was tempting, say so in the PR body: "Considered also doing B because of <scenario>, but the manifest cache key already segregates by mode, so the scenario isn't reachable." This makes the choice reviewable and prevents the next agent from "fixing the gap" later.

## Common mistakes

- **"It's just one line, why not."** One line × every fix × every agent = an accumulating crust of unmotivated defensive code that hides the next real bug.
- **"Defense in depth is good practice."** Defense in depth is for *separate invariants at separate layers* (auth + authz + validation). Stacking two enforcement layers for the *same* invariant is duplication, not defense in depth.
- **"The test locks the contract."** A test that pins the backstop tests the implementation, not the contract. Pin user-observable behavior and the contract survives whichever layer enforces it.
- **"But here's a scenario where it could fail."** Almost any code has such a scenario under contortion. The standard is "is this scenario reachable from real usage?", not "can I imagine it?"
- **"I'll be defensive while I'm here."** No. The PR is for the root-cause fix. Drive-by defensive code goes in a separate PR with its own justification, where it can be rejected on its own merits.
- **"The reviewer will catch it if I'm wrong."** Reviewers approve defensive code more often than they should because it looks careful. Don't outsource the judgment.
- **"It's just a hash, mixing more inputs can't hurt."** It can. Now the next agent has to figure out which inputs the hash is supposed to capture, and why. Hashes that mix unmotivated inputs lose their meaning as identity contracts.
- **"The producer might be wrong in the future."** Then fix the producer's contract (types, schema, tests) so it can't be wrong. Don't accept-and-defend wrong data at the consumer.

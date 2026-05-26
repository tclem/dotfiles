---
name: deprecating-and-removing
description: Use when removing old code, sunsetting a feature, consolidating duplicate implementations, or migrating consumers off an API — and the repository has no equivalent skill of its own.
---

# Deprecating and Removing

Code is a liability. Every line costs ongoing tests, dependency updates, security patches, and the attention of whoever reads nearby code next. The value is the functionality, not the bytes. When the functionality moves to a better implementation, the old code has to go — not just get a `#[deprecated]` attribute (or `Deprecated:` rdoc, or `@deprecated` JSDoc) and live on forever as zombie surface area.

A repo-local deprecation or release-management skill, if it exists, supersedes this one.

## When to use

Load this skill when you're about to:

- Replace one API, system, or library with another and need to retire the old path.
- Sunset a feature, endpoint, flag, or config that no longer earns its keep.
- Consolidate two implementations of the same thing into one.
- Delete code you think nobody depends on — but haven't verified.
- Add a deprecation marker (`#[deprecated]` in Rust, a `Deprecated:` doc comment in Go, rdoc `Deprecated:` in Ruby, `@deprecated` JSDoc/TS) or a migration notice without a plan for the eventual removal.
- Design a new public API, feature flag, external contract, or long-lived integration where removability is a material design constraint.

Don't load it for:

- Lockstep-deployed code where the producer and all consumers ship as one artifact (see Scope below) — just delete and replace.
- Bug fixes that happen to delete code — the deletion is the fix, not a deprecation.
- Routine refactors that don't change a public contract (renaming an internal function, moving a file).

## Scope: lockstep vs decoupled consumers

The rules below assume consumers can't migrate in the same change as the producer. The full ceremony — advisory vs compulsory, deprecator-owns-migration, build-the-replacement-first, removal windows — earns its place when:

- The API is **external**: an open-source crate, gem, or package with users you can't grep; a public HTTP, gRPC, or Twirp API; an SDK.
- Producer and consumers ship on **separate cadences**: a backend service deprecating an endpoint used by independently-deployed clients; a library version that other repos pin.
- Consumers are **numerous or unowned**: even inside the org, if you can't reach every caller in one PR, you need a migration window.

When the producer and all consumers ship in lockstep — meaning the producer change cannot reach users until every consumer is updated, and you can release them together as one atomic unit — skip the ceremony. Examples: a desktop app where the Rust backend and the TS/JS frontend release as one artifact; a refactor entirely behind a crate or module boundary you fully own and the boundary doesn't cross a deploy unit. A monorepo containing independently deployed services, jobs, CLIs, or extensions is **not** lockstep — grepability isn't the test, release atomicity is.

Delete the old code and update the call sites in the same PR (or a tight series of PRs that all merge before the next release). Rules 1–7 below would just add bureaucracy. Rule 8 (design for eventual removal) still applies.

If you're unsure which mode you're in, ask: "Can the producer change reach users before every consumer is updated?" If no, lockstep. If yes, decoupled.

## Rules

### 1. Don't deprecate without a working replacement

A deprecation notice without a replacement is a tax on users with no path forward. Build the replacement, prove it in production for the critical use cases, then deprecate the old one. "We'll build the new thing in parallel" is how you end up maintaining both forever.

If the replacement isn't ready, the work is "build the replacement," not "deprecate the old thing."

### 2. The deprecator owns the migration

If you're the one retiring the old code, you are responsible for moving its consumers off — either by migrating them yourself or by shipping a backward-compatible path that requires no consumer action. Announcing a deadline and walking away is not deprecation; it's externalizing your cleanup cost onto everyone downstream.

The exception: when consumers are outside your reach (public API, OSS users), you owe them docs, tooling, and lead time proportional to the breakage.

### 3. Default to advisory; reserve compulsory for real cost

| Type | Use when | Mechanism |
|---|---|---|
| **Advisory** | The old path is stable and the cost of keeping it is low | Warnings, docs, nudges, no hard deadline |
| **Compulsory** | Maintenance burden, security risk, or blocked progress justifies forcing migration | Hard removal date with migration tooling and support |

Compulsory deprecation without migration tooling is just a threat. If you're going to force a deadline, ship the codemod, the script, or the docs that make migrating mechanical.

### 4. Quantify the blast radius before you commit

Before you commit to a deprecation, answer these in writing (PR body, ADR, or design doc):

- Who calls this today? (Search the codebase, the org, public usage if applicable.)
- What's the migration cost per consumer? (Trivial codemod, one-line change, or "rewrite their integration"?)
- What does this cost to keep? (Concrete maintenance, security, or complexity cost — not vibes.)
- What's the replacement, and is it actually better, or just newer?

If you can't answer all four, you're not ready to deprecate. "We should probably remove this someday" is not a plan.

### 5. Migrate consumers incrementally, then remove

For each consumer: update, verify (tests, integration check, prod signal as appropriate), confirm no regressions, then move on. Migrating in big-bang batches turns a routine cleanup into a multi-week incident.

When the consumer count is zero — *verified*, not assumed — delete the old code. Don't leave it as `@deprecated` decoration for another year. Zombie code with a deprecation warning is still code; it still needs patches and still confuses readers.

### 6. Don't add new dependencies on something you're deprecating

The fastest way to undo a deprecation effort is to have a teammate (or your earlier self) write fresh code against the deprecated API while the migration is in flight. When you deprecate, add a guardrail that catches new uses — in Rust, treat `#[deprecated]` warnings as errors in CI (`-D deprecated` or `#![deny(deprecated)]` at the crate root); in Go, a `staticcheck` `SA1019` rule; in Ruby/TS, a lint rule or grep-based CI check. At minimum, note in the deprecation announcement that new uses will be reverted.

### 7. Removal is the goal, not deprecation

Treat the deprecation marker (`#[deprecated]`, `Deprecated:` doc comment, `@deprecated`) as a milestone, not a destination. Every deprecation should have a removal plan with a target version or date — even an advisory one. For semver-versioned crates and libraries, name the version that removes it (e.g. "removed in 2.0"). Skills that stop at "add the warning" are how every codebase ends up with a graveyard of `// TODO: remove after 2.0` comments that outlive the engineer who wrote them.

### 8. Design with eventual removal in mind

When building something new, ask: "How would we remove this in three years?" Systems with narrow public surfaces, feature flags, and clean module boundaries are removable. Systems that leak implementation details into every consumer are forever. The cost of removability is paid at design time; the cost of not paying it compounds.

## Common mistakes

- **"We'll mark it deprecated and remove it later."** "Later" is where deprecations go to die. If there's no removal plan, it's not deprecated, it's annotated.
- **"The consumers will migrate themselves."** They won't, or they'll migrate on a timeline that makes your removal impossible. Either own the migration or accept that the code stays.
- **"Two implementations is fine for now."** Two implementations of the same thing is twice the maintenance, twice the bug surface, and indefinite confusion about which one is canonical. Pick one, migrate, delete the other.
- **"Let's just add a deprecation warning."** A warning without a migration path is noise. Users mute it, the warning rots, and the code outlives the warning's relevance.
- **"It's only a few lines — leave it."** A few lines per deprecated path × every deprecation × every year = the crust that makes the codebase slow to change. The cost of code isn't the lines; it's the gravitational pull on everyone who reads them.
- **"I'll deprecate this properly even though I own all the callers."** Re-read Scope. If everything ships in lockstep, skip the ceremony and delete in one PR. Adding `#[deprecated]` to code you're about to delete in the same release is theater.
- **"Compulsory by next quarter."** Compulsory without tooling is a threat, not a plan. If migration requires manual work from every consumer and you haven't built the codemod, you don't have a deadline, you have an incident waiting.
- **"We can't remove it; something might still use it."** Then verify. If nothing uses it, delete it. If something does, that's your migration list. "Might" is not a reason to leave dead code.

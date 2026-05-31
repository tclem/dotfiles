---
name: code-rust
description: "Use when editing or reviewing Rust files (*.rs) and the repository has no rust-coding-skill of its own."
---

# Rust Coding

User-level fallback for Rust style and discipline. Apply when working in a
Rust repository that does not provide its own `rust-coding-skill` (or
equivalent). When a repo-local Rust skill exists, prefer it — it carries
project-specific conventions this skill cannot.

A starter template that mirrors this content with extension stubs for
project-specific rules lives at
`copilot/templates/rust-coding-skill/SKILL.md` in `tclem/dotfiles`. Use
the template when bootstrapping a new repo's Rust skill; use this skill
when no repo skill exists yet.

## When to use

Use this when changing or reviewing Rust code in any repo that does not
provide a narrower repo-local Rust skill.

Do not use this to override repository style guides, generated code
conventions, or project-specific API patterns.

## Priority hierarchy

From most important to least important:

1. **Readable code** — every line should earn its place.
2. **Correct code** — especially in concurrent and async contexts.
3. **Performant code** — think about allocations, data structures, hot paths.

## Error handling

- **`thiserror` for typed error enums** at module and library boundaries. Name
  variants by what the caller should do (`ShardNotFound`, `AuthRequired`,
  `IndexCorrupted`), not by where the error came from (`DbError`, `ParseError`,
  `HttpError`).
- **`anyhow` only at the binary boundary** — top-level handlers, CLI entry
  points, server commands. Never in library code.
- **Avoid `Box<dyn std::error::Error + Send + Sync>` as a return type.** It
  erases type information, prevents matching on specific failures, and produces
  opaque messages with no causal chain. Use a `thiserror` enum.
- **No `unwrap()` in production code.** Use `?` to propagate, `let-else` for
  early returns, `if let` / `match` for branches, or `expect("specific
  invariant")` for truly infallible cases. `unwrap()` is for tests.
- **Don't write `is_none()` / `is_err()` followed by `unwrap()`** — use `if
  let` or `match`. The separate check is redundant and easy to desync.
- **Destructure multiple `Option`s together:** `let (Some(a), Some(b)) = (x, y)
  else { return Err(...); };`.
- **`panic!` only for unrecoverable invariants** where the whole application is
  broken. Not for localized failures.
- **`#[error(transparent)]`** for wrapped errors that should pass through
  unchanged.
- **Prefer errors over `Option`** when absence indicates a non-recoverable
  violation rather than an expected missing value.

## Async and concurrency

- **Prefer awaited futures over spawning tasks.** Futures get cancelled with
  the parent and can borrow locals. Spawn only when work must outlive the
  caller, then track the `JoinHandle` or document the lifecycle owner.
- **Rayon for CPU-bound parallelism, Tokio for async I/O fan-out.**
- **Blocking sync I/O:** `tokio::task::spawn_blocking` for short operations
  (the blocking pool is bounded — don't saturate it with multi-second work).
  Long-lived workers use a dedicated thread.
- **Never hold a lock across `.await`.** Use channels (`tokio::sync::mpsc` /
  `oneshot`) or restructure so the critical section finishes before the await.
- **Lock choice:**
  - `parking_lot::Mutex` — common default; short critical sections that never
    touch `.await`.
  - `std::sync::Mutex` — use when you want poisoning for invariant-critical
    state.
  - `tokio::sync::Mutex` — last resort, only when the lock genuinely must be
    held across `.await`.
- **`std::sync::LazyLock` for lazy statics** (stable since Rust 1.80). Do not
  introduce `once_cell::Lazy` in new code.
- **No module-level mutable statics.** Make state a field on the owning
  struct and thread `&self` through. Immutable `LazyLock<Regex>` /
  `LazyLock<Config>` are fine.
- **Bound fan-out:** `stream::iter(...).buffer_unordered(N)` over unbounded
  `join_all` on dynamic collections.
- **Fix large futures directly.** Hoist join branches into `Box::pin` locals;
  don't `#[allow]` `clippy::large_futures` and don't raise thread stack size
  as a workaround.

## Traits and conversions

- **Avoid custom traits when possible.** They break code navigation. Prefer
  plain functions on the concrete type. Standard derives (`Iterator`,
  `Future`, `Display`, `Debug`, `Clone`, `Default`, `PartialEq`, `Hash`,
  `Serialize`/`Deserialize`, `thiserror::Error`) are fine. Real extension
  seams where the consumer must be pluggable are also fine — document why.
- **No `From`/`Into` for contextual conversions.** Prefer named methods:
  `to_record`, `into_parts`, `from_row`, `as_string`. `From`/`Into` can't
  carry context, can't fail expressively, and produce un-navigable call
  sites where the target type is implicit.
- **Iterators replace visitor patterns.**
- **Closures over ~10 lines become named functions.** Anonymous closures are
  invisible in stack traces and hard to navigate.
- **Avoid multiple generic `F: Fn(...)` parameters.**

## Tracing and logging

- **Static messages with structured fields**, never interpolated dynamic data:

```rust
  // Good
  tracing::info!(shard_id = %id, path = %path.display(), "shard indexed");
  // Bad
  tracing::info!("shard {} indexed at {}", id, path.display());
  ```

- **Prefer manual `error_span!` over `#[tracing::instrument]`.** The attribute
  is easy to misuse: wrong level by default, captures all args, hides span
  lifetime from readers.
- **Default to `error_span!`, not `info_span!`.** Span level controls the
  minimum filter at which the span is recorded. Under a `warn`/`error`
  filter, an `info_span` is dropped, taking its fields and parent context
  with it.
- **Never hold a `span.enter()` guard across `.await`.** Use
  `.instrument(span)` instead.

## Testing

- **Avoid mock testing.** Depend on real implementations, spin up lightweight
  versions, or split side-effectful functions into a pure core (takes values)
  plus a thin wrapper (fetches them).
- **`assert_eq!(actual, expected)`** — actual first for readable diffs.
- **`unwrap()` is fine in tests** — not in production.
- **Tests must run concurrently.** Unique test data, temp directories,
  `serial_test` only when truly necessary.
- **Mark slow or integration tests with `#[ignore]`.**

## Imports

- **All `use` statements at the top of the file.** Never import items inline
  within function bodies.
- **Prefer top-level imports over fully-qualified paths** in expressions and
  match arms.
- **One `use` per line, group items from the same module with braces:**

  ```rust
  use std::collections::{HashMap, HashSet};
  use std::sync::Arc;
  ```

## Code organization

- **One concept per file.**
- **Extract repeated patterns into helpers on the third usage.** Don't DRY
  prematurely — avoid extracting the wrong abstraction.
- **`pub(crate)` by default.** Only `pub` when the API is truly public.
- **Prefer `#[expect(...)]` over `#[allow(...)]`** for lint suppression.
  Apply on individual fields, not whole structs.
- **Reserve blank lines for semantic section boundaries** — between
  setup / execute / respond phases.
- **Avoid trivial temporary `let` bindings.**
- **Inline format args:** `println!("{value:?}")` not `println!("{:?}", value)`.
- **No `..Self::default()` in production struct constructors.** Explicitly
  list all fields so adding a new field causes a compile error at every
  construction site.

## Pattern matching

- **Prefer exhaustive matches over `_` wildcards.** When an enum gains a
  variant, a wildcard arm silently swallows it. Exhaustive matches force
  every call site to handle the new case.

## Build speed

- **Minimize dependency feature flags.** Audit with `cargo tree`; find unused
  deps with `cargo machete`.
- **Iterate with `cargo check`**, not `cargo build`.

## Comments

Comments explain **why**, never **what**. Engineers can read code. Decision
test before writing any comment: "If I delete this, what is lost that can't
be recovered by reading the code, types, names, and one navigation jump?"
If the answer is "nothing," don't write it.

Anti-patterns: doc comments enumerating function body, block comments that
paraphrase the next line, "this is used by X" pointers, flow-narrating
bullets inside a function.

## Common mistakes

- Treating this skill as permission to reformat or rewrite unrelated Rust.
  Apply the smallest coherent change that improves the code you are touching.
- Adding a trait because several types have similar methods. Start with
  functions and concrete types; introduce a trait only when callers need
  polymorphism.
- Wrapping errors in strings too early. Preserve typed errors inside
  libraries; add human context at the application boundary.
- Spawning a task to solve ownership or lifetime friction. Prefer
  restructuring so the parent future owns cancellation and error propagation.
- Adding defensive fallbacks for impossible states. Encode the invariant in
  types or return a real error.
- Loading this skill instead of a repo-local rust-coding-skill. If the repo
  has one, that one wins — its project-specific rules trump anything here.

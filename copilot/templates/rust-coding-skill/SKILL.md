---
name: rust-coding-skill
description: "Use when editing or reviewing Rust files (*.rs) in this repository."
---

# Rust Coding Skill

Opinionated Rust style and discipline rules for this codebase. Apply when
writing, reviewing, or refactoring Rust.

> Template: copied from `tclem/dotfiles/copilot/templates/rust-coding-skill/`.
> Prune sections that do not apply and fill in the "Project-specific
> extensions" stubs at the bottom.

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
  struct and thread `&self` through. Global mutability makes tests
  non-deterministic and couples unrelated code paths. Immutable
  `LazyLock<Regex>` / `LazyLock<Config>` are fine.
- **Bound fan-out:** `stream::iter(...).buffer_unordered(N)` over unbounded
  `join_all` on dynamic collections.
- **Fix large futures directly.** Hoist join branches into `Box::pin` locals;
  don't `#[allow]` `clippy::large_futures` and don't raise thread stack size
  as a workaround.

## Traits and conversions

- **Avoid custom traits when possible.** They break code navigation — when
  the call site goes through a trait, the IDE can't resolve the concrete
  type. Prefer plain functions on the concrete type. Standard derives
  (`Iterator`, `Future`, `Display`, `Debug`, `Clone`, `Default`, `PartialEq`,
  `Hash`, `Serialize`/`Deserialize`, `thiserror::Error`) are fine. Real
  extension seams where the consumer must be pluggable are also fine —
  document why.
- **No `From`/`Into` for contextual conversions.** Prefer named methods:
  `to_record`, `into_parts`, `from_row`, `as_string`. `From`/`Into` can't
  carry context, can't fail expressively, and produce un-navigable call
  sites where the target type is implicit.
- **Iterators replace visitor patterns.** Extract traversal into an `iter()`
  method.
- **Closures over ~10 lines become named functions.** Anonymous closures are
  invisible in stack traces and hard to navigate. A closure that is
  essentially the whole function body (e.g. wrapping in a timeout) is fine
  inline.
- **Avoid multiple generic `F: Fn(...)` parameters.** One callback is often
  unavoidable; two or more is a sign the function should be restructured.

## Tracing and logging

- **Static messages with structured fields**, never interpolated dynamic
  data:

  ```rust
  // Good
  tracing::info!(shard_id = %id, path = %path.display(), "shard indexed");
  // Bad
  tracing::info!("shard {} indexed at {}", id, path.display());
  ```

  Static messages are greppable to one emit site; dynamic fields enable
  aggregation.

- **Prefer manual `error_span!` over `#[tracing::instrument]`.** The
  attribute is easy to misuse: wrong level by default, captures all args,
  hides span lifetime from readers.
- **Default to `error_span!`, not `info_span!`.** Span level controls the
  minimum filter at which the span is recorded. Under a `warn`/`error`
  filter, an `info_span` is dropped, taking the span's fields and parent
  context with it — and child error events lose correlation. `error_span!`
  is always present.
- **Never hold a `span.enter()` guard across `.await`.** The guard is
  thread-local; when a future resumes on a different thread, the span
  attaches to the wrong work. Use `.instrument(span)` instead. In purely
  synchronous closures (e.g. inside `spawn_blocking`), `let _g =
  span.enter();` is fine.

```rust
use tracing::Instrument;

async fn do_work(&self, id: Id) -> Result<()> {
    let span = tracing::error_span!("do_work", %id);
    async {
        // body
    }
    .instrument(span)
    .await
}
```

## Testing

- **Avoid mock testing.** Depend on real implementations, spin up
  lightweight versions, or split side-effectful functions into a pure core
  (takes values) plus a thin wrapper (fetches them).

  ```rust
  // Bad — mock the storage trait
  let storage = MockStorage::new().expect_get().returns(item);
  let result = foo(&storage);

  // Good — pure core over real data
  let item = Item { /* ... */ };
  let result = foo_core(&item);
  ```

- **`assert_eq!(actual, expected)`** — actual first for readable diffs.
- **`unwrap()` is fine in tests** — not in production.
- **Tests must run concurrently.** Unique test data, temp directories,
  `serial_test` only when truly necessary.
- **Mark slow or integration tests with `#[ignore]`.**

## Imports

- **All `use` statements at the top of the file.** Never import items
  inline within function bodies.
- **Prefer top-level imports over fully-qualified paths** in expressions
  and match arms. Long qualified paths add noise.
- **One `use` per line, group items from the same module with braces:**

  ```rust
  // Good
  use std::collections::{HashMap, HashSet};
  use std::sync::Arc;

  // Bad — split same module across lines
  use std::collections::HashMap;
  use std::collections::HashSet;

  // Bad — inline import
  fn foo() {
      use std::sync::Arc;
  }
  ```

## Code organization

- **One concept per file.**
- **Extract repeated patterns into helpers on the third usage.** Don't DRY
  prematurely — avoid extracting the wrong abstraction.
- **`pub(crate)` by default.** Only `pub` when the API is truly public.
- **Prefer `#[expect(...)]` over `#[allow(...)]`** for lint suppression.
  `#[expect]` warns when the suppression becomes unnecessary, so stale
  attributes don't accumulate. Apply on individual fields, not whole
  structs.
- **Reserve blank lines for semantic section boundaries** — between
  setup / execute / respond phases. Do not insert blank lines between
  consecutive statements that are part of the same logical step.
- **Avoid trivial temporary `let` bindings.** If a value is used once and
  the expression is clear, inline it. `let x = foo.clone(); bar(x)` is
  just `bar(foo.clone())`.
- **Inline format args:** `println!("{value:?}")` not `println!("{:?}",
  value)`.
- **No `..Self::default()` in production struct constructors.** Explicitly
  list all fields so adding a new field causes a compile error at every
  construction site. `..Default::default()` is fine in tests for brevity.

## Pattern matching

- **Prefer exhaustive matches over `_` wildcards.** When an enum gains a
  variant, a wildcard arm silently swallows it. Exhaustive matches cause
  a compile error at every call site, which is what you want.
- **Use `_` only for truly unbounded types** (integers, strings) or when
  the arm genuinely applies to all future variants.

## Build speed

- **Minimize dependency feature flags.** Avoid kitchen-sink `full` features
  unless the repo standardizes on them. Audit with `cargo tree`; find unused
  deps with `cargo machete`.
- **Iterate with `cargo check`**, not `cargo build`.

## Comments

Comments explain **why**, never **what**. Engineers can read code.

The training-data default is to doc-comment every function with a summary
of what it does and a bullet list of its behaviors. Override it. Function
names, types, and one `go to definition` jump already cover that; a
summary comment drifts on the first refactor and adds nothing.

Decision test before writing any comment: "If I delete this, what is lost
that can't be recovered by reading the code, types, names, and one
navigation jump?" If the answer is "nothing," don't write it.

### Anti-patterns

- Doc comments that enumerate behavior visible in the function body.
- Block comments that paraphrase the next line (`// Build the request`
  above `let request = build_request(...)`).
- "This is used by X" pointers when X is findable via `findReferences`.
- Flow-narrating bullets inside a function. If the flow needs a map,
  refactor the function.

### Worth commenting

- Non-obvious invariants between variables or call order.
- Why a specific constant value was chosen and what breaks if changed.
- Why the obvious alternative was rejected.
- Cross-cutting context a reader wouldn't find by navigating.

## Common mistakes

- Treating this skill as permission to reformat or rewrite unrelated Rust.
  Apply the smallest coherent change that improves the code you are
  touching.
- Adding a trait because several types have similar methods. Start with
  functions and concrete types; introduce a trait only when callers need
  polymorphism.
- Wrapping errors in strings too early. Preserve typed errors inside
  libraries and add human context at the application boundary.
- Spawning a task to solve ownership or lifetime friction. Prefer
  restructuring so the parent future owns cancellation and error
  propagation.
- Adding defensive fallbacks for impossible states. Encode the invariant
  in types or return a real error.

## Project-specific extensions

Fill in or delete as appropriate for this repo. Anything in this section
is repo-local — keep generic guidance above the line.

### Runtime wrappers

If this repo has a runtime crate that wraps task spawning, blocking
pools, or rayon (e.g. for tracing-context and request-id propagation),
document the wrappers here and require them over raw `tokio::spawn` /
`tokio::task::spawn_blocking` / `rayon::spawn`.

### Banned macros and lints

List anything enforced by `clippy.toml` or local lint config:
`#[tracing::instrument]`, `Runtime::Builder::thread_stack_size`,
disallowed types, etc.

### Domain ID newtypes

If this repo has typed newtype IDs (sessions, workspaces, projects,
etc.), list them and the rule: new code uses the newtype, never raw
`String` / `&str`.

### Error codes

For repos that expose Twirp / gRPC / HTTP APIs, document how to pick
codes by caller action (transient vs. invariant violation vs. concurrent
modification vs. precondition).

### Database, schema, migrations

Repo-specific rules for connection management, lock discipline, migration
file layout, and DML vs. DDL boundaries.

### Cross-platform

Path construction, separators, canonicalization, branch-to-path encoding,
test path normalization — list whatever this repo cares about.

### Benchmarks

Map source files to bench suites and document the baseline-comparison
recipe.

---
name: go-coding-skill
description: "Use when editing or reviewing Go files (*.go) in this repository."
---

# Go Coding Skill

Opinionated Go style and discipline rules for this codebase. Apply when
writing, reviewing, or refactoring Go.

> Template: copied from `tclem/dotfiles/copilot/templates/go-coding-skill/`.
> Prune sections that do not apply and fill in the "Project-specific
> extensions" stubs at the bottom.

See [`AGENTS.md`](../../../AGENTS.md) for environment setup and the
build/test/lint contract. `go fmt` + `golangci-lint` are the source of
truth for mechanical rules — this document covers judgment calls the
linter can't enforce.

## Priority hierarchy

From most important to least important:

1. **Readable code** — every line should earn its place.
2. **Correct code** — especially in concurrent and CGO contexts.
3. **Performant code** — think about allocations, hot paths, garbage.

## Error handling

- **Wrap errors with `%w` and add context at the call site.** Include
  what the function was trying to do, not a restatement of the
  underlying error. Keep the message **static** — dynamic data goes on
  the wrapped error or as structured log fields, so log aggregators
  can group by message:

  ```go
  // Bad — no context, just propagates
  return err
  // Bad — %v drops the chain
  return fmt.Errorf("fetch repo: %v", err)
  // Bad — dynamic data in the message hurts grouping
  return fmt.Errorf("fetch repo %d: %w", id, err)
  // Good — static message + wrap; log the id as a structured field
  return fmt.Errorf("fetch repo: %w", err)
  ```

  When the caller needs the id structurally (for retries, error pages,
  etc.), prefer a typed error struct over baking it into the message.

- **Sentinel errors with `errors.New`** for expected, matchable
  outcomes:
  ```go
  var ErrActorNotFound = errors.New("actor not found")
  ```
  Callers use `errors.Is(err, ErrActorNotFound)`.
- **Typed error structs** when the caller needs data off the error
  (IDs, retry hints) — implement `Error()` and `Unwrap()` if wrapping.
  Match with `errors.As`.
- **Never return a bare `interface{}`/`any` or stringly-typed error.**
  If callers might branch on a failure mode, give it a sentinel or
  type.
- **No `panic` in library code.** Reserve for unrecoverable invariant
  violations in `main` or initialization. Request paths return errors.
- **No `log.Fatal` outside `main`.** Libraries return errors; the
  entry point decides whether to exit.
- **Don't discard errors silently.** If genuinely ignorable, assign to
  `_` with a comment explaining why.
- **Check `errors.Is(err, context.Canceled)` /
  `errors.Is(err, context.DeadlineExceeded)` before logging** —
  cancellation is normal.

## Concurrency and context

- **`context.Context` is the first argument** on every function that
  does I/O, blocking work, or calls another context-aware function.
  Name it `ctx`. Don't store a context in a struct in new code; thread
  it through calls.
- **Don't use `context.Background()` except at entry points** (main,
  test setup, top-level goroutines that must outlive the request).
  Propagate the caller's context.
- **Prefer `errgroup.WithContext` over bare `go` for fan-out.** It
  handles error propagation and cancellation. Always bound concurrency
  with `SetLimit`:

  ```go
  g, ctx := errgroup.WithContext(ctx)
  g.SetLimit(maxConcurrent)
  for _, shard := range shards {
      g.Go(func() error { return index.Search(ctx, shard, query) })
  }
  if err := g.Wait(); err != nil { return err }
  ```

- **Every goroutine needs a defined lifetime.** Know who cancels it.
  Unbounded `go` over a caller-supplied slice is both a lifetime and a
  fan-out bug:

  ```go
  // Bad — unbounded goroutines, detached context, swallowed errors
  func (c *Cache) Warm(ids []RepoID) {
      for _, id := range ids {
          go func(id RepoID) {
              repo, _ := c.fetch(context.Background(), id)
              c.store(id, repo)
          }(id)
      }
  }

  // Good — bounded, cancellable, errors surfaced
  func (c *Cache) Warm(ctx context.Context, ids []RepoID) error {
      g, ctx := errgroup.WithContext(ctx)
      g.SetLimit(16)
      for _, id := range ids {
          g.Go(func() error {
              repo, err := c.fetch(ctx, id)
              if err != nil {
                  return fmt.Errorf("warm repo: %w", err)
              }
              c.store(id, repo)
              return nil
          })
      }
      return g.Wait()
  }
  ```

- **Always `defer cancel()`** after `context.WithTimeout` /
  `WithCancel`.
- **Don't hold a `sync.Mutex` across I/O or a channel send/receive.**
  Copy out, release, then block.
- **Channels for coordination, mutexes for protecting state.**
- **Avoid `sync.Once` for lazy state on a shared struct.** Initialize
  in the constructor. Reserve `sync.Once` for package-level lazy
  statics.
- **No package-level mutable globals.** Make state a field on the
  owning struct. Immutable package-level values (regexes, configs)
  are fine.
- **`time.After` in a `select` leaks the timer until it fires.** In a
  long-lived loop, use `time.NewTimer` + `defer t.Stop()` or
  `context.WithTimeout`.

## Interfaces

- **Accept interfaces, return concrete structs.**
- **Keep interfaces small.** `io.Reader` / `io.Writer` is the
  aspiration.
- **Define interfaces where they're consumed, not where they're
  implemented.**
- **Don't define an interface for a single implementation "for
  testing".** Use a real implementation or a pure-core/thin-wrapper
  split.
- **`any` is rarely the right parameter type.** Prefer generics or a
  small interface.
- **No ambient stubs.** Named function values over long inline
  closures.

## Logging and observability

> **Project-specific stub:** Document the structured logger and tag
> helpers this repo uses (e.g. `go-telemetry/logging` + `go-kvp`,
> `slog`, `zap`). Show one canonical `Info` call and one `Error` call.

- **Static messages with structured fields**, never interpolated
  dynamic data:

  ```go
  // Good
  logger.Info(ctx, "actor fetched from cache", "actor_id", id, "elapsed", time.Since(start))
  // Bad — string interpolation defeats aggregation
  logger.Info(ctx, fmt.Sprintf("fetched actor %d in %s", id, time.Since(start)))
  ```

- **Always log the error as a structured field**, not `err.Error()`
  in the message.
- **Don't log and return.** Pick one: log where the error is handled,
  or return and let the caller decide.
- **Log level guidance:**
  - `Debug` — chatty per-request diagnostics.
  - `Info` — expected state changes worth seeing in aggregate.
  - `Warn` — recoverable anomalies worth investigating.
  - `Error` — actionable failures.
- **Don't log `context.Canceled` / `DeadlineExceeded` at `Error`.**

## Testing

- **Table-driven tests** are the canonical shape:
  ```go
  func TestParse(t *testing.T) {
      tests := []struct {
          name string
          in   string
          want Result
          err  error
      }{
          {name: "bare term", in: "foo", want: Result{Term: "foo"}},
      }
      for _, tc := range tests {
          t.Run(tc.name, func(t *testing.T) {
              got, err := Parse(tc.in)
              if !errors.Is(err, tc.err) {
                  t.Fatalf("err = %v, want %v", err, tc.err)
              }
              require.Equal(t, tc.want, got)
          })
      }
  }
  ```
- **`t.Parallel()` is optional** — be consistent with surrounding
  code. When you add it, put it at both top-level and sub-test.
- **Mocking:** prefer not to mock at all. Depend on real
  implementations, in-memory fakes, or split the pure core from the
  I/O wrapper:
  ```go
  func summarize(repo Repo) Summary { ... }
  func Summarize(ctx context.Context, c *Client, id ID) (Summary, error) {
      r, err := c.Fetch(ctx, id)
      if err != nil { return Summary{}, fmt.Errorf("summarize: %w", err) }
      return summarize(*r), nil
  }
  ```
  When a fake is genuinely needed, use whatever generator the repo
  standardized on. Never introduce a second mocking library.
- **`*testing.T` + `t.Helper()`** in shared test helpers; fail with
  `t.Fatal`.
- **`t.Cleanup` over `defer`** for teardown.
- **`t.TempDir()`** for filesystem fixtures.
- **`testify/require` over `testify/assert`** when failure should stop
  the test. Bare `t.Fatalf` with a clear message is also fine.
- **Gate external-service tests by runtime env vars, not build tags.**
  `t.Skipf` when the env var is unset so plain `go test ./...` stays
  hermetic.

## Imports

- **`goimports` groups: stdlib, third-party, local.**
- **No blank imports** except for registration side effects (DB
  drivers, pprof). Comment why.
- **No dot imports.**
- **Alias imports sparingly.**

## Code organization

- **For new files, one concept per file.**
- **Package names: short, lowercase, single-word, no underscores.**
  Don't repeat the package name in type names (`auth.Client`, not
  `auth.AuthClient`).
- **`internal/` by default** unless the package is a deliberate
  public API.
- **Exported identifiers require doc comments.** Start with the
  identifier name.
- **Keep functions compact.** A function that doesn't fit on a screen
  wants extraction.
- **Early return over nested `if`.**
- **`make(..., 0, n)` when you know the size.**
- **Don't pre-optimize, don't pre-DRY.** Extract on the third usage.

## Comments

Comments explain **why**, never **what**. Decision test: "If I delete
this, what is lost that can't be recovered by reading the code, types,
names, and one navigation jump?" If "nothing," don't write it.

Anti-patterns: doc comments enumerating function body, block comments
that paraphrase the next line, "this is used by X" pointers,
flow-narrating bullets inside a function.

Worth commenting: non-obvious invariants, why a constant was chosen,
why the obvious alternative was rejected, CGO/unsafe/cross-goroutine
assumptions.

## Project-specific extensions

> Fill in the rules below that are specific to this repository. Delete
> stubs that don't apply. Add new sections as needed.

### RPC / API conventions

> e.g. Twirp error code mapping, gRPC status conventions, internal RPC
> framework rules.

### Logging library

> Name the logger and the canonical call shape. Link the package.

### CGO / FFI

> If the repo uses CGO, name the wrapper packages and the rules around
> pointer passing, build tags, and bootstrap.

### Integration test gating

> Document the env vars that gate external-service tests
> (`RUN_INT_TESTS`, etc.) and where each lives.

### Vendoring / private deps

> If the repo vendors deps or has private go-modules, document the
> workflow here.

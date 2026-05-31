---
name: code-go
description: "Use when editing or reviewing Go files (*.go) and the repository has no go-coding-skill of its own."
---

# Go Coding

User-level fallback for Go style and discipline. Apply when working in a
Go repository that does not provide its own `go-coding-skill` (or
equivalent). When a repo-local Go skill exists, prefer it — it carries
project-specific conventions this skill cannot.

A starter template that mirrors this content with extension stubs for
project-specific rules lives at
`copilot/templates/go-coding-skill/SKILL.md` in `tclem/dotfiles`. Use
the template when bootstrapping a new repo's Go skill; use this skill
when no repo skill exists yet.

## When to use

Use this when changing or reviewing Go code in any repo that does not
provide a narrower repo-local Go skill.

Do not use this to override repository style guides, generated code
conventions, or project-specific API patterns (Twirp, gRPC, internal
RPC frameworks, etc.).

## Priority hierarchy

From most important to least important:

1. **Readable code** — every line should earn its place.
2. **Correct code** — especially in concurrent and CGO contexts.
3. **Performant code** — think about allocations, hot paths, garbage.

`go fmt` + `golangci-lint` are the source of truth for mechanical
rules. This skill covers judgment calls the linter cannot enforce.

## Error handling

- **Wrap errors with `%w` and add context at the call site.** Include
  what the function was trying to do, not a restatement of the
  underlying error. Keep the message **static** — dynamic data goes on
  the wrapped error or as structured log fields, so log aggregators
  can group by message:

  ```go
  // Bad — no context
  return err
  // Bad — %v drops the chain
  return fmt.Errorf("fetch repo: %v", err)
  // Bad — dynamic data in the message hurts grouping
  return fmt.Errorf("fetch repo %d: %w", id, err)
  // Good — static message + wrap; log the id as a structured field
  return fmt.Errorf("fetch repo: %w", err)
  ```

- **Sentinel errors with `errors.New`** for expected, matchable
  outcomes; callers branch with `errors.Is`.
- **Typed error structs** when the caller needs data off the error
  (IDs, retry hints). Implement `Error()` and `Unwrap()`; match with
  `errors.As`.
- **Never return a bare `interface{}`/`any` or stringly-typed error.**
  If callers might branch on a failure mode, give it a sentinel or
  type.
- **No `panic` in library code.** Reserve panics for unrecoverable
  invariant violations in `main` or initialization. Request paths
  return errors.
- **No `log.Fatal` outside `main`.** Libraries return errors; the
  entry point decides whether to exit.
- **Don't discard errors silently.** If an error is genuinely
  ignorable, assign to `_` with a comment explaining why.
- **Check `errors.Is(err, context.Canceled)` /
  `errors.Is(err, context.DeadlineExceeded)` before logging** —
  cancellation is normal and shouldn't generate error noise.

## Concurrency and context

- **`context.Context` is the first argument** on every function that
  does I/O, blocking work, or calls another context-aware function.
  Name it `ctx`. Don't store a context in a struct in new code;
  thread it through calls.
- **Don't use `context.Background()` except at entry points** (main,
  test setup, top-level goroutines that must outlive the request).
  Propagate the caller's context.
- **Prefer `errgroup.WithContext` over bare `go` for fan-out.** It
  handles error propagation and cancellation. Always bound
  concurrency on unbounded inputs with `SetLimit` (or a semaphore
  channel) — unbounded fan-out is a self-DOS:

  ```go
  g, ctx := errgroup.WithContext(ctx)
  g.SetLimit(maxConcurrent)
  for _, item := range items {
      g.Go(func() error { return process(ctx, item) })
  }
  if err := g.Wait(); err != nil { return err }
  ```

- **Every goroutine needs a defined lifetime.** If you spawn a
  goroutine, know who cancels it. `go func()` without `ctx.Done()`
  or a stop channel is usually a bug.
- **Always `defer cancel()`** after `context.WithTimeout` /
  `WithCancel`.
- **Don't hold a `sync.Mutex` across I/O or a channel send/receive.**
  Copy out what you need, release the lock, then do the blocking
  work.
- **Channels for coordination, mutexes for protecting state.** "Share
  memory by communicating" when the shape fits; mutexes when you
  need to guard a map or counter.
- **Avoid `sync.Once` for lazy state on a shared struct.** Initialize
  in the constructor. Reserve `sync.Once` for package-level lazy
  statics (and even then, prefer passing the value in).
- **No package-level mutable globals.** Make state a field on the
  owning struct and thread `*T` through. Global mutability makes
  tests non-deterministic. Immutable package-level values (regexes,
  configs loaded at startup) are fine.
- **`time.After` in a `select` leaks the timer until it fires.**
  Inside a long-lived loop, use `time.NewTimer` + `defer t.Stop()`
  or `context.WithTimeout`.

## Interfaces

- **Accept interfaces, return concrete structs.** The caller chooses
  abstraction; the callee shouldn't force a type name.
- **Keep interfaces small.** One or two methods is typical. `io.Reader`
  / `io.Writer` is the aspiration.
- **Define interfaces where they're consumed, not where they're
  implemented.** The package that needs `Fetcher` declares
  `Fetcher`; the package that satisfies it doesn't need to know.
- **Don't define an interface for a single implementation "for
  testing".** It's a smell — test with a real implementation or
  split the logic into a pure core + thin wrapper.
- **`any` is rarely the right parameter type.** Prefer generics
  (`[T any]`) or a small interface.
- **No ambient stubs.** Prefer named function values over long inline
  closures — named functions show up in stack traces.

## Logging and observability

- **Static messages with structured fields**, never interpolated
  dynamic data. Whatever structured logger the project uses, follow
  this rule:

  ```go
  // Good
  logger.Info(ctx, "actor fetched from cache", "actor_id", id, "elapsed", time.Since(start))
  // Bad — string interpolation defeats aggregation
  logger.Info(ctx, fmt.Sprintf("fetched actor %d in %s", id, time.Since(start)))
  ```

- **Always log the error as a structured field**, not `err.Error()`
  in the message — keeps the causal chain intact.
- **Don't log and return.** Pick one: log where the error is handled
  (near `main` / RPC handler), or return and let the caller decide.
  Logging at every layer produces duplicate stack-noise.
- **Log level guidance:**
  - `Debug` — chatty per-request diagnostics, off in production.
  - `Info` — expected state changes worth seeing in aggregate.
  - `Warn` — recoverable anomalies worth investigating.
  - `Error` — actionable failures; someone should look.
- **Don't log `context.Canceled` / `DeadlineExceeded` at `Error`.**
  Callers canceling is normal; demote or skip.
- **Context carries request IDs and trace spans.** Don't pass request
  or trace IDs as separate function arguments.

## Testing

- **Table-driven tests.** The canonical shape:

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

- **Prefer not to mock at all.** Depend on real implementations,
  lightweight in-memory fakes, or restructure so the pure core takes
  values as input and a thin wrapper does the I/O:

  ```go
  // Pure core — trivially testable
  func summarize(repo Repo) Summary { ... }

  // Thin wrapper — no logic to test
  func Summarize(ctx context.Context, c *Client, id ID) (Summary, error) {
      r, err := c.Fetch(ctx, id)
      if err != nil { return Summary{}, fmt.Errorf("summarize: %w", err) }
      return summarize(*r), nil
  }
  ```

  Reach for a generated fake (counterfeiter, mockery — whichever the
  repo standardized on) only when the boundary genuinely needs it.
  Never introduce a new mocking library on top of an existing one.
- **`*testing.T` + `t.Helper()`** in shared test helpers. Helpers
  that fail call `t.Fatal`, not return errors.
- **`t.Cleanup` over `defer`** for teardown — survives helper-return
  and ordering is explicit.
- **`t.TempDir()`** for filesystem fixtures. Never `os.TempDir` +
  manual cleanup.
- **`testify/require` over `testify/assert`** when a failure should
  stop the test. Bare `t.Fatalf` with a clear message is also fine.
- **Gate external-service tests by runtime env vars, not build
  tags.** Tests that need Docker, a DB, or Redis check an env var
  (`RUN_INT_TESTS`, etc.) and `t.Skipf` when unset, so plain
  `go test ./...` stays hermetic.

## Imports

- **`goimports` groups: stdlib, third-party, local.** Enforced by
  `golangci-lint`; run lint before pushing.
- **No blank imports (`_ "..."`) except for registration side
  effects** (DB drivers, pprof). Comment why.
- **No dot imports (`. "..."`).** They shadow identifiers and break
  navigation.
- **Alias imports sparingly.** Only when two packages collide. Don't
  rename for cosmetics.

## Code organization

- **For new files, one concept per file.** Don't refactor existing
  large files opportunistically — those are intentionally laid out.
- **Package names: short, lowercase, single-word, no underscores.**
  Don't repeat the package name in type names (`auth.Client`, not
  `auth.AuthClient`).
- **`internal/` is your friend.** Default to `internal/` unless the
  package is a deliberate public API.
- **Exported identifiers require doc comments.** Start the comment
  with the identifier name: `// Fetcher retrieves ...`. Unexported
  code doesn't need doc comments — reserve comments for *why*.
- **Keep functions compact.** A function that doesn't fit on a
  screen is telling you to extract something.
- **Early return over nested `if`.** Guard clauses first; happy path
  unindented at the bottom.
- **`make(..., 0, n)` when you know the size.** Avoid repeated slice
  growth in hot paths. Same for `map` capacity hints.
- **Don't pre-optimize, don't pre-DRY.** Extract on the third usage,
  not the second.

## Comments

Comments explain **why**, never **what**. Engineers can read code.
Decision test before writing any comment: "If I delete this, what is
lost that can't be recovered by reading the code, types, names, and
one navigation jump?" If "nothing," don't write it.

Anti-patterns:

- Doc comments that enumerate behavior visible in the function body.
- Block comments that paraphrase the next line (`// Build the request`
  above `req := buildRequest(...)` is noise).
- "This is used by X" pointers when X is findable via
  `findReferences`.
- Flow-narrating bullets inside a function. If the flow needs a map,
  refactor.

Worth commenting:

- Non-obvious invariants between fields or call order.
- Why a specific constant was chosen and what breaks if it changes.
- Why the obvious alternative was rejected.
- CGO / unsafe / cross-goroutine assumptions a reader wouldn't catch.

## Common mistakes

- Treating this skill as permission to reformat or rewrite unrelated
  Go. Apply the smallest coherent change that improves the code you
  are touching.
- Adding an interface because several types have similar methods.
  Start with concrete types; introduce an interface only when
  callers need polymorphism.
- Spawning a goroutine without a defined lifetime or fan-out bound.
  Unbounded `go` over caller-supplied slices is both a lifetime and
  a DOS bug.
- Holding a mutex across blocking calls (channel send, RPC,
  lock-contended I/O).
- Wrapping errors in strings too early. Preserve typed errors inside
  libraries; add human context at the application boundary.
- Logging and returning the same error at every layer — produces
  duplicate stack-noise.
- Loading this skill instead of a repo-local Go skill. If the repo
  has one, that one wins — its project-specific rules trump anything
  here.

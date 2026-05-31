---
name: reading-source-code
description: Use when about to call a library, crate, or framework API you haven't verified, when a dependency's behavior is surprising, when training-data memory might be stale, or when investigating how a dependency actually behaves.
---

# Reading Source Code

Read the actual source before you write code against it. Training data goes stale, docs lag the implementation, and "I remember this API" is the most common source of plausible-looking but wrong code. The source is almost always reachable in seconds — read it.

This skill is about the discipline. The *how* (where the source lives, which search tool to use) is mechanical and varies by ecosystem.

## When to use

Load this skill when you're about to:

- Call a function, method, or macro from a third-party library or framework and you're working from memory rather than something you just read.
- Use a config field, attribute, or annotation whose exact name, type, or accepted values you'd be guessing at.
- Pattern-match on an error type, response shape, or struct field you haven't verified exists in the version this project uses.
- Reach for "the idiomatic way to do X in <framework>" without checking what the current version actually exposes.
- Investigate behavior that surprises you ("why does this return None here?") — the source explains it; speculation doesn't.
- Debug an interaction between your code and a dependency where the dependency's behavior is the unknown.

Don't load it for:

- Pure logic that doesn't depend on any external API (loops, data structures, your own functions).
- APIs you've verified against the project's pinned version *in this session* — don't re-read on every call.
- Trivial standard-library usage in a language you work in daily (Rust `std`, Go stdlib, Ruby core, common Node built-ins).

## Rules

### 1. Pin the version before you read anything

Read the dependency file first — `Cargo.toml` + `Cargo.lock`, `go.mod` + `go.sum`, `Gemfile.lock`, or `package.json` + lockfile. The version determines which source matters. Reading docs or source for the wrong version is worse than not reading at all — it produces confident, wrong code.

In Rust this matters more than anywhere else: a function may have been added, renamed, or had its trait bounds changed between adjacent minor versions of a crate, and `cargo` will happily resolve to whichever matches the `Cargo.lock`.

### 2. Prefer the source over the docs when they disagree

Official docs are a strong signal but lag the implementation, sometimes by major versions. When the source and the docs disagree, the source wins for the version you're on. When the source and a blog post or Stack Overflow answer disagree, it's not a contest.

Source hierarchy, strongest first:

1. The pinned version's actual source — `~/.cargo/registry/src/...` for Rust crates, `$(go env GOMODCACHE)` for Go modules, the gem's install path (`bundle info <gem> --path`) for Ruby, `node_modules/` for JS/TS, vendored deps, or the matching tag on GitHub.
2. Generated API docs from the same source — `cargo doc --open`, `go doc <pkg>.<sym>`, `ri <Class>`, `tsserver`/editor hover.
3. Official docs site for the pinned version (not "latest" unless they match).
4. The project's changelog or release notes for the version range you're crossing.
5. Language/runtime references (the Rust Reference, the Go spec, MDN).

Stack Overflow, blog posts, and your own training data are starting points, not citations.

### 3. Read narrowly and recently

Don't try to internalize the whole crate or package. Find the type, function, or trait you're about to use and read *its* definition and immediate neighbors. For unfamiliar APIs, also read one or two usage sites in the dependency's own tests — Rust's `tests/` and `src/**/*.rs` `#[cfg(test)]` blocks, Go's `*_test.go`, Ruby's `spec/`, JS's `__tests__/` — they show the contract better than the prose docs do.

For cross-repo reading at GitHub, `gh blackbird` (see `blackbird-search`) jumps straight to symbols and usages without cloning. For local source, `rg` inside the registry cache, `GOMODCACHE`, gem path, or `node_modules` is usually faster than a web fetch.

### 4. Say what you read, not how you "STACK DETECTED"

When you've grounded a non-obvious choice in source, mention it briefly and link to it once — e.g. "Using `tokio::task::JoinSet` (added in tokio 1.21; `~/.cargo/registry/src/.../tokio-1.38.0/src/task/join_set.rs`)." Don't narrate a ceremony of detection steps. The user cares about the citation, not the ritual.

If you couldn't find the source — e.g. the dependency is closed-source or only available via a binary — say so explicitly: "I couldn't verify this against the source; treating the docs as authoritative."

### 5. Flag conflicts with the existing codebase out loud

If the source-grounded approach contradicts a pattern already in the repo, surface it instead of silently picking one:

> The current code calls `reqwest::Client::new()`, but the crate now recommends `reqwest::Client::builder()...build()` for any client that needs non-default timeouts (see `src/client.rs:412` in `reqwest-0.12.4`). Want me to migrate this call, match the existing pattern, or leave it for a separate PR?

Let the user choose. Don't quietly modernize and don't quietly cargo-cult.

### 6. Don't bluff when the source isn't reachable

If you can't reach the source in this session (no network, dep not vendored, closed-source SDK) and you're not confident from recent reading, *say so* and either ask the user, write the smallest thing that compiles and can be checked, or stop. A confident wrong implementation costs more than a paused one.

## Common mistakes

- **"I know this API."** Maybe. Reading takes 30 seconds and prevents 30 minutes of debugging a hallucinated method name. The cost asymmetry is enormous.
- **"The docs say X."** Which version's docs? Pinned to what? The docs site usually defaults to "latest," and "latest" may be one or two majors ahead of the project.
- **Reading the README instead of the source.** The README is marketing-grade overview. The source is the contract. For anything beyond "what is this crate," go straight to the type or function you're using.
- **Re-reading on every call in the same session.** Once you've verified an API for this version, you don't need to re-verify it for the next adjacent call. This skill is about not bluffing, not about ritual repetition.
- **Citing Stack Overflow as a source.** SO answers are clues for what to read, not authority. If an SO answer points to a doc page or source file, cite *that*.
- **Silently modernizing.** Finding that the current code uses a deprecated pattern is not license to migrate it as a side effect. Surface the conflict and let the user decide.
- **Pretending you read it.** If you didn't actually open the file, don't pattern-match a plausible-looking citation onto your guess. Either read it or say you didn't.

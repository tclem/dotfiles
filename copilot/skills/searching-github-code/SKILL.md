---
name: searching-github-code
description: Use when searching code across repos you don't have checked out, asking conceptual "how does X work" questions across the org, or needing JSON-shaped code-search output for programmatic consumption.
---

# Searching GitHub Code

`gh blackbird` is a superset of grep. Use it when the question is bigger than "grep this checkout": multi-repo scope, GitHub code-search qualifiers (`language:`, `path:`, `symbol:`), exact language-aware symbol lookup, or vector search over embeddings. Pick the *mode* (lexical / symbol / semantic) before reaching for `rg`.

## Not exhaustive

`gh blackbird` is more like Google than grep: it returns top-ranked results capped by `-n` (defaults 25 lexical, 10 semantic), not every match. Treat output as a ranked sample, never as a complete set. **If you need every occurrence - for a refactor, a security sweep, a "did we miss any callers" check - clone the repo and use `rg` on the checkout.** That is the only tool that promises exhaustiveness here.

## When to use

- Multiple repos in one query, no cloning.
- "Where is symbol X defined or called?" - exact, language-aware, beats regex.
- Conceptual / natural-language questions ("how does token resolution work in service Y?") - vector search over embeddings, not pattern matching.
- Lexical queries that benefit from GitHub code-search qualifiers (`language:rust`, `path:**/migrations/`, `symbol:Foo`, `repo:owner/name`).
- Broad lexical queries on large local repos where Blackbird's index beats a cold `rg` scan.
- Need JSON output for programmatic consumption / piping to `jq`.

Not for:

- Exhaustive enumeration. Use `rg` on a checkout when you need *every* match (refactors, security sweeps, "did we miss any callers"). See *Not exhaustive* above.
- Tiny repos or narrow queries on a local checkout where an `rg` round-trip beats a network call.
- Filesystem-aware work `rg` is good at (binary heuristics, hidden files, `--vimgrep` piping into an editor).
- GHES hosts. External filesets are dotcom only - do not call them against `*.ghe.com`.

## Mode picker

- **Lexical** - you know the string or regex. Use the GitHub code-search query syntax.
- **`--symbol`** - you know the name. Language-aware; do not approximate with regex.
- **`--semantic`** - you only know the concept. Vector search over embeddings; single repo; returns nearest neighbors, not an exhaustive set.

## How to invoke

Always pass `--json` (= `--format jsonl`) when an agent will parse the output. First line is a meta envelope, then one match per line. Never parse `pretty`.

```sh
# Lexical with code-search qualifiers
gh blackbird search 'TokenResolver language:rust path:src/auth' -R owner/name --json

# Multi-repo lexical
gh blackbird search 'parseURL' -R a/b -R c/d --json

# Exact symbol lookup (language-aware)
gh blackbird search --symbol parse_url -R owner/name --json

# Semantic / conceptual (single repo, may need indexing)
gh blackbird search --semantic "how does token resolution work" -R owner/name --auto-index --json

# External fileset (dotcom only)
gh blackbird search 'pattern' --fileset my-corpus --json
```

Cap results with `-n` when scoping a broad query. Defaults: 25 lexical, 10 semantic.

## Rules

- Always `--json` for programmatic use. Never grep `pretty`.
- `--semantic` accepts at most one `-R`. Lexical accepts many.
- Pair `--semantic` with `--auto-index` against repos that may not be indexed yet, otherwise expect a 404.
- Use `--symbol` for name lookup; do not regex around it.
- Use `--semantic` for conceptual questions; do not lexical-search a paraphrase.
- Do not pass `--lab` (staff-only no-op).
- No GHES. No filesets on `*.ghe.com`.
- Context flags (`-C/-A/-B`) only affect `pretty`. Irrelevant when consuming `--json`.

## Common mistakes

- Grepping `pretty` output instead of using `--json`.
- Reaching for `rg` reflexively when the right tool is `--symbol` or `--semantic`.
- Approximating symbol search with a regex when `--symbol` exists.
- Using lexical search for a conceptual question when `--semantic` (vector search) would find better matches.
- Multiple `-R` flags with `--semantic` (rejected).
- Forgetting `--auto-index` on `--semantic` against an unindexed repo (404).
- Treating Blackbird results as exhaustive in any mode - it is top-N ranked, not every match. For exhaustiveness, clone and `rg`.

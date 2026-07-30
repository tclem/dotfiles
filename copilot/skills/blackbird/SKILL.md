---
name: blackbird
description: 'Use when reaching for `gh blackbird` (Blackbird code search) for cross-repo lexical, symbol, or semantic search on GitHub — finding callers, ownership, or how systems work without cloning.'
---

# Blackbird Search

`gh blackbird` is a superset of grep for indexed GitHub code: many repos at once, GitHub code-search qualifiers, language-aware symbol lookup, and vector search over embeddings.

**Blackbird or `rg`?** `rg` when the repo is checked out *and* you need every occurrence — refactors, security sweeps, "did we miss a caller." Blackbird for everything else: repos you don't have, a symbol, a concept.

- Results are **top-N ranked**, not every match. Never present them as exhaustive.
- The index covers the **default branch only** — no working tree, no feature branch, no unmerged PR. Check anything you are actively changing with `rg`.

## Canonical invocations

```sh
# Agent default: token-capped JSONL (--for-llm == --max-tokens 4000 --format jsonl)
gh blackbird search 'TokenResolver path:src/auth' -R owner/name --for-llm -n 10

# Grep-style: explicit context + width clip. Mutually exclusive with --for-llm.
gh blackbird search 'parseURL' -R a/b -R c/d --json -C 3 -M 200

# Exact symbol lookup, language-aware
gh blackbird search --symbol parse_url -R owner/name --for-llm
```

`--for-llm` caps the response at 4000 tokens; a bare `--json` has no cap, so one broad query can flood context. Switch to `--json` only for the grep-style flags (`-A`/`-B`/`-C`/`-M`/`--full-snippet`, mutually exclusive with `--for-llm`), a different `--max-tokens`, or after a run reports `results_incomplete: true`. Always pass one of them — with no format flag the output depends on whether stdout is a TTY, and neither default is capped.

Everything else is in `gh blackbird search --help`.

## Lexical ANDs every term

A lexical query is not a prompt. A single bare term is already broad — it matches a file's **content** or its **path**, so `ingest_pipeline` finds `tests/ingest_pipeline.rs` even though the string appears nowhere inside it. Multiple bare terms are ANDed, so each one you add is another filter the same file must satisfy. Guess one identifier wrong and the query silently returns nothing, which reads like "absent from this repo" rather than "I made that name up":

```sh
# Wrong — `getChangedFilesState` is a guess, and one bad term zeroes the result
gh blackbird search 'repositoryStateCache getChangedFilesState' -R desktop/desktop --for-llm -n 10

# Right — one distinctive identifier, then read the file it lands in
gh blackbird search 'repositoryStateCache' -R desktop/desktop --for-llm -n 10
```

Pick the **single most distinctive** token — the rarest identifier, string literal, route, or config key — and let the file it lands in supply the rest. If you have several candidate names and don't know which exists, `OR` them into one query rather than running them in sequence. Bare multi-term AND is for narrowing a hit you already have, not for describing what you're looking for.

To sharpen a term rather than add one, qualify it. `symbol:`, `def:`, `path:`, and `content:` each scope to a single domain and accept a regex, so `def:RepositoryStateCache` finds the definition where the bare term returns every file that mentions it. A bare `/regex/` searches content only.

Mode decision rule:

- A concrete identifier, literal, path, or regex → **lexical**.
- A name you already know → **`--symbol`**. Do not approximate it with a regex.
- A concept, or a question you can't name a token for → **`--semantic`**. If you're stacking terms because you aren't sure what you're looking for, that's the tell.

## Scoping

`-R owner/name` folds into the lexical query as a `repo:` qualifier — for lexical the two are identical. **Use `-R`.** It is also the only form that scopes `--semantic`, which sends your query verbatim as the embedding prompt and builds its filter from `-R` alone; an inline `repo:` there embeds as prompt text and filters nothing.

Query cheaply; quotas are cost-based, and lexical and semantic have separate limits:

1. Scope before broadening: add `-R`, `path:`, `language:`, or a more distinctive literal before raising `-n`.
2. Start at `-n 5` or `-n 10`. Raise it only after the first page proves the query is correctly scoped.
3. `OR` is the cheap shape for a disjunction — one query beats N sequential ones for the same candidates. It turns expensive when the terms are *generic*: each floods on its own and the union is noise. Distinctiveness decides, not the operator.
4. Clip pathological lines with `-M 200` when results include minified or generated code.
5. Stop once you have a canonical file, owner repo, route, or schema. Reading one result beats another broad search.

Code search is case-insensitive, so case variants are never worth a query: `octokit` already finds `Octokit`. `OR` genuine spelling variants into one query rather than firing separate searches — batching them into a single shell call behind `|| true` hides the cost without reducing it.

## Ownership discovery

`--semantic` is single-repo, so it is a bad first move for "who owns X?" — a guessed repo returns plausible, irrelevant neighbors. Lexically search the proper noun, service name, route, or config key across likely repos, then read the owner repo's docs and routes. Use `--semantic` inside that repo only if the docs don't answer the concept.

## Caller tracing

Real callers usually go through a wrapper, not the raw type. Start at the callee definition, find the generated client or SDK helper around it, and search **that** symbol. For an RPC endpoint the fully-qualified names beat the bare ones: prefer `SomeService::Client.count`, `/twirp/example.v1.QueryAPI/Count`, or `Example::V1::CountRequest` over `CountRequest`. Check paths before concluding — tests, fakes, fixtures, and generated code all look like callsites.

## Rate limits

A 429 means you have exhausted the rate limit for that mode; a semantic 429 says nothing about lexical quota. With `--json` the error arrives as JSONL carrying `retry_after_seconds` and/or `rate_limit_reset_epoch_seconds`. Honor it **once**: wait the stated interval plus a cushion, tighten the query, retry. If that also 429s or the wait is long, stop and tell the user — include the mode and the cheaper query you would try next. Do not spin.

## Rules

- `--semantic` accepts at most one `-R`; lexical accepts many.
- Pair `--semantic` with `--auto-index` on repos that may not be indexed yet, or expect a 404.
- Prefer `jq` one-liners or reading the file over ad-hoc post-processing scripts.
- Supported hosts are `github.com` and Proxima data-residency tenants (`<tenant>.ghe.com`). Self-hosted GHES is out of scope — that hostname fails with `UnsupportedHost` before a request is made.

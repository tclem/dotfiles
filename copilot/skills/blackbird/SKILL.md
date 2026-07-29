---
name: blackbird
description: 'Use when reaching for `gh blackbird` (Blackbird code search) for cross-repo lexical, symbol, or semantic search on GitHub — finding callers, ownership, or how systems work without cloning.'
---

# Blackbird Search

`gh blackbird` is a superset of grep for indexed GitHub code. Reach for it when the question is bigger than a local checkout: multiple repos, GitHub code-search qualifiers, language-aware symbol lookup, or vector search. It returns top-N ranked results, never every match — when you need exhaustiveness, clone and `rg`.

## Canonical invocations

```sh
# Agent default: token-capped JSONL (--for-llm == --max-tokens 4000 --format jsonl)
gh blackbird search 'TokenResolver path:src/auth' -R owner/name --for-llm -n 10

# Grep-style: explicit context + width clip. Mutually exclusive with --for-llm.
gh blackbird search 'parseURL' -R a/b -R c/d --json -C 3 -M 200

# Exact symbol lookup, language-aware
gh blackbird search --symbol parse_url -R owner/name --for-llm
```

`--for-llm` is the default because it bounds response size; a bare `--json` has no token cap and one broad query can flood context. Reach for `--json` only when you need the grep-style flags, a non-4000 `--max-tokens`, or a previous `--for-llm` run returned `results_incomplete: true`. Never parse `pretty`.

Everything else is in `gh blackbird search --help`. Read that instead of guessing at flags; this skill does not mirror it.

## Lexical ANDs every term

A lexical query is not a prompt. Every bare term must appear in the same file, so prose returns nothing:

```sh
# Wrong — three unrelated identifiers ANDed, zero results, retries burn quota
gh blackbird search 'repositoryStateCache changesState diff' -R desktop/desktop --json -n 10

# Right — one distinctive identifier, then read the file it lands in
gh blackbird search 'repositoryStateCache' -R desktop/desktop --for-llm -n 10
```

Pick the **single most distinctive** token — the rarest identifier, string literal, route, or config key — and let the file it lands in supply the rest. Multi-term lexical is for narrowing a known-good hit, not for describing what you're looking for.

Mode decision rule:

- A concrete identifier, literal, path, or regex → **lexical**.
- A name you already know → **`--symbol`**. Do not approximate it with a regex.
- A sentence or a concept → **`--semantic`**. If you catch yourself writing prose into lexical, you wanted semantic.

None of these is `rg`. Falling back to a local grep is right when the repo is checked out and the scope is local — not when the question is a symbol, a concept, or spans repos you don't have.

## Scoping

`-R owner/name` folds into the lexical query as a `repo:` qualifier — it is the same thing as writing `repo:owner/name` inline. **Use `-R`, always.** It is repeatable, it reads clearly, and it is the only form that scopes `--semantic`: semantic sends the query verbatim as the embedding prompt and builds its scoping filter from `-R` alone, so an inline `repo:` there is embedded as prompt text and silently filters nothing. Do not mix the two conventions.

Query cheaply; quotas are cost-based, with separate lexical and semantic buckets:

1. If the repo is checked out and the scope is local, use `rg` instead.
2. Scope before broadening: add `-R`, `path:`, `language:`, or a more distinctive literal before raising `-n`.
3. Start at `-n 5` or `-n 10`. Raise it only after the first page proves the query is correctly scoped.
4. Split broad `OR` queries into narrower ones. A five-term `OR` across a large repo is one expensive query that also floods output.
5. Clip pathological lines with `-M 200` when results include minified or generated code.
6. Stop once you have a canonical file, owner repo, route, or schema. Reading one result beats another broad search.

Code search is case-insensitive: `octokit` already finds `Octokit`. Do not fire off case or spelling variants of the same query — not sequentially, and not batched into one shell call behind `|| true`. Batching hides the cost; it is still N queries against the same quota. Run one query, read the result, then decide.

## Ownership discovery

`--semantic` is single-repo, so it is a bad first move for "who owns X?" — a guessed repo returns plausible, irrelevant neighbors. Lexically search the proper noun, service name, route, or config key across likely repos first, identify the owner repo, then read its docs/README/routes. Use `--semantic` inside that repo only if the docs don't answer the concept.

## Caller tracing

Blackbird is for callers in repos you don't have locally. For "did we get every caller," use `rg` on a checkout — never present ranked results as exhaustive.

Real callers usually go through a wrapper, not the raw type. Start at the callee definition, find the generated client or SDK helper around it, and search **that** symbol. For an RPC endpoint, the fully-qualified names beat the bare ones: prefer `SomeService::Client.count`, `/twirp/example.v1.QueryAPI/Count`, or `Example::V1::CountRequest` over `CountRequest`. Check paths before concluding — tests, fakes, fixtures, and generated code look like callsites.

## Rate limits

A 429 means the bucket for that mode is exhausted; a semantic 429 says nothing about lexical quota. With `--json`, the error arrives as JSONL carrying `retry_after_seconds` and/or `rate_limit_reset_epoch_seconds`.

Honor the metadata **once**: wait the stated interval plus a cushion, make the query cheaper (lower `-n`, tighter scope, split `OR`s), retry. If that also 429s or the wait is long, stop and tell the user — include the mode and the cheaper query you'd try next. Do not spin.

## Rules

- `--semantic` accepts at most one `-R`; lexical accepts many.
- Pair `--semantic` with `--auto-index` on repos that may not be indexed yet, or expect a 404.
- `-A`/`-B`/`-C`/`-M`/`--full-snippet` are lexical-only and mutually exclusive with `--for-llm`. Pick the LLM mode or the grep-style mode, not both.
- Prefer `jq` one-liners or reading the file over ad-hoc post-processing scripts.
- `--fileset` (a client-ingested corpus, searched instead of GitHub-indexed repos) is dotcom only. Normal lexical and semantic search work fine against `*.ghe.com`.
- Do not pass `--lab` (staff-only, currently defaulted on anyway).

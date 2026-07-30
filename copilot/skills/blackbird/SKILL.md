---
name: blackbird
description: 'Use when reaching for `gh blackbird` (Blackbird code search) for cross-repo lexical, symbol, or semantic search on GitHub — finding callers, ownership, or how systems work without cloning.'
---

# Blackbird Search

`gh blackbird` is a superset of grep for indexed GitHub code. **Blackbird or `rg`?** `rg` when the repo is checked out *and* you need every occurrence — refactors, security sweeps, "did we miss a caller." Blackbird for everything else: repos you don't have, a symbol, a concept.

- Results are **top-N ranked**, not every match. Never present them as exhaustive.
- The index covers the **default branch only** — no working tree, no feature branch, no unmerged PR. Check anything you are actively changing with `rg`.

## Canonical invocations

```sh
# Agent default: no output flags. Piped output is already token-capped JSONL.
gh blackbird search 'TokenResolver path:src/auth' -R owner/name -n 10

# Grep-style: explicit context + width clip, which drops the token cap
gh blackbird search 'parseURL' -R a/b -R c/d -C 3 -M 200

# Exact symbol lookup, language-aware
gh blackbird search --symbol parse_url -R owner/name

# Cross-repo question, no repo in hand: scope to the org
gh blackbird search 'TokenResolver org:some-org' -n 10
```

Override only for a reason. Grep-style flags (`-A`/`-B`/`-C`/`-M`/`--full-snippet`) keep JSONL but drop the budget — reach for them when you need fixed context or to clip minified lines. `--max-tokens N` sets a different budget, worth using after a run reports `results_incomplete: true`, not pre-emptively. `--format pretty` and `--format oneline` are for humans and drop the budget too; never parse them.

Everything else is in `gh blackbird search --help`.

## Lexical ANDs every term

A lexical query is not a prompt. A single bare term is already broad — it matches a file's **content**, its **path**, or a **symbol** it defines, so it hits files that contain the string nowhere. Multiple bare terms are ANDed, so each one you add is another filter the same file must satisfy. Guess one identifier wrong and the query silently returns nothing, which reads like "absent from this repo" rather than "I made that name up":

```sh
# Wrong — `getChangedFilesState` is a guess, and one bad term zeroes the result
gh blackbird search 'repositoryStateCache getChangedFilesState' -R desktop/desktop -n 10

# Right — one distinctive identifier, then read the file it lands in
gh blackbird search 'repositoryStateCache' -R desktop/desktop -n 10
```

Pick the **single most distinctive** token — the rarest identifier, string literal, route, or config key — and let the file it lands in supply the rest. If you have several candidate names and don't know which exists, `OR` them into one query rather than running them in sequence. Bare multi-term AND is for narrowing a hit you already have, not for describing what you're looking for.

To sharpen a term rather than add one, qualify it. `symbol:`, `def:`, `path:`, and `content:` each scope to a single domain and accept a regex, so `def:RepositoryStateCache` finds the definition where the bare term returns every file that mentions it. A bare `/regex/` searches content only.

Mode decision rule:

- A name you already know → **`--symbol`**. Do not approximate it with a regex.
- A concept, or a question you can't name a token for → **`--semantic`**. If you're stacking terms because you aren't sure what you're looking for, that's the tell.

## Scoping

Know the repo → `-R owner/name`, repeatable for a set. Don't know it → `org:`, `user:`, or `enterprise:` inline in the query; there are no flags for those. Narrow further with `path:` and `language:`.

Unscoped works too, but results are top-N over everything you can see — fine for a distinctive token, thin for a common one. Scope when you can say where the answer lives.

`--semantic` **requires exactly one** `-R`. Unscoped is a 422, and an inline `repo:` is embedded as prompt text and filters nothing. When you don't know the repo, find it lexically first.

Query cheaply; quotas are cost-based, and lexical and semantic have separate limits:

1. Scope before broadening: add `-R`, `org:`, `path:`, `language:`, or a more distinctive literal before raising `-n`.
2. Start at `-n 5` or `-n 10`. Raise it only after the first page proves the query is correctly scoped.
3. `OR` is the cheap shape for a disjunction — one query beats N sequential ones for the same candidates. It turns expensive when the terms are *generic*: each floods on its own and the union is noise. Distinctiveness decides, not the operator.
4. Clip pathological lines with `-M 200` when results include minified or generated code.
5. Stop once you have a canonical file, owner repo, route, or schema. Reading one result beats another broad search.

Code search is case-insensitive, so case variants are never worth a query: `octokit` already finds `Octokit`. `OR` genuine spelling variants into one query rather than firing separate searches — batching them into a single shell call behind `|| true` hides the cost without reducing it.

## Caller tracing

Real callers usually go through a wrapper, not the raw type. Start at the callee definition, find the generated client or SDK helper around it, and search **that** symbol. For an RPC endpoint, fully-qualified names beat bare ones: `Example::V1::CountRequest` over `CountRequest`. Check paths before concluding — tests, fakes, fixtures, and generated code all look like callsites.

## Exit codes

| Exit | Meaning |
| ---- | ------- |
| `0`  | Success, **including zero results** and a reader that closed the pipe early (`head`, `jq -e first`) |
| `1`  | API, network, or validation error — a `{"type":"error", ...}` JSONL record on stdout |
| `2`  | Argument parse error |

Zero results is not a failure. Do not wrap calls in `|| true` or redirect stderr with `2>&1`; a non-zero exit is real and worth reading.

## Rules

- On a 429, honor the error's `retry_after_seconds` once with a cheaper query, then stop and report. Lexical and semantic limits are separate.
- Pair `--semantic` with `--auto-index` on repos that may not be indexed yet, or expect a 404.
- The result cap is `-n` / `--limit`. `--max-results` is not a flag and exits 2 with a pointer.
- Prefer `jq` one-liners or reading the file over ad-hoc post-processing scripts.
- Supported hosts are `github.com` and Proxima data-residency tenants (`<tenant>.ghe.com`). Self-hosted GHES is out of scope — that hostname fails with `UnsupportedHost` before a request is made.
- `gh blackbird` can search external filesets for a local corpus that is not a GitHub repo. Load the `blackbird-fileset` skill for that workflow.

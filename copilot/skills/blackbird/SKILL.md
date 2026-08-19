---
name: blackbird
description: 'Use when searching code in a GitHub checkout or across remote GitHub repositories with `gh blackbird`.'
---

# Blackbird Search

`gh blackbird` combines GitHub's remote code-search index with uncommitted changes in the current working tree. It supports regex patterns, symbol lookup, semantic search, org- and enterprise-wide queries, and ranked or exhaustive results.

## Recommended usage

- Exploring concepts, new domains, and natural-language questions: use `gh blackbird search --semantic`.
- Finding code across an org, enterprise, or several repos: use `org:`/`user:`/`enterprise:`, or repeat `-R owner/name`. This is especially useful when you don't have local clones.
- Searching another known GitHub repo: use `-R owner/name`.
- Searching the current full checkout: omit `-R`; Blackbird infers `origin` and includes working-tree changes.
- Searching large repos with ranked or exhaustive results: Blackbird can avoid scanning files covered by the remote index.
- Looking up named symbols, definitions, and references in GitHub's remote index.

Search first, then verify. Blackbird locates the code; `view` and `rg` confirm what it found and supply surrounding detail. Reaching for grep to *discover* what exists is the common mistake.

## Canonical invocations

```sh
# Agent default in the target checkout: no repo or output flags.
gh blackbird search 'TokenResolver path:src/auth' -n 10

# Grep-style: explicit context + width clip, which drops the token cap
gh blackbird search 'parseURL' -R a/b -R c/d -C 3 -M 200

# Exhaustive over the current full checkout's code-search corpus
gh blackbird search --exhaustive 'parseURL'

# Natural-language search in the current checkout
gh blackbird search --semantic 'where is authentication resolved?'

# Exact symbol lookup, language-aware
gh blackbird search --symbol parse_url -R owner/name

# Cross-repo question, no repo in hand: scope to the org
gh blackbird search 'TokenResolver org:some-org' -n 10
```

## Scoping

Working in the target checkout → omit `-R` and let Blackbird infer `origin`. Targeting another known repo → `-R owner/name`, repeatable for a set. Don't know it → `org:`, `user:`, or `enterprise:` inline in the query. Narrow further with `path:` and `language:`.

Outside a GitHub checkout, no scope means top-N results across everything you can see. An inline `repo:` in a semantic prompt is prompt text, not a scope; use `-R` or inferred `origin`.

## Modes

- Lexical search is the default: ranked unless you pass `--exhaustive`.
- Know the name → use `--symbol`. Know the concept → use `--semantic`.
- `--semantic` accepts at most one `-R`; in a GitHub checkout, omitting it infers `origin`.
- `--exhaustive` returns every match in the `.gitignore`-filtered code-search corpus. Binary, non-UTF-8, vendored/generated, and otherwise unsuitable files are excluded to match GitHub's remote corpus.
- `--remote-only` skips working-tree correction while retaining an inferred or explicit repository scope. Multiple `-R` values are already remote-only.

## Output

- Piped output defaults to JSONL. Piped lexical search also defaults to a 4000-token snippet budget; semantic results are already chunked.
- Grep-style flags are supported (`-A`/`-B`/`-C`/`-M`/`--full-snippet`).
- Workspace JSONL differs from remote-only JSONL. Use `--remote-only` when an existing consumer requires the established remote schema.

Everything else is in `gh blackbird search --help`.

## Lexical ANDs every term

A lexical query is not a prompt: bare terms are ANDed, so one guessed identifier can zero the result. Start with the single most distinctive term, use `OR` for uncertain alternatives, then narrow with `def:`/`symbol:`/`path:`/`content:`. A bare `/regex/` searches content only.

```sh
# One guessed term zeroes the query
gh blackbird search 'repositoryStateCache getChangedFilesState' -R desktop/desktop -n 10

# Start with the name you know
gh blackbird search 'repositoryStateCache' -R desktop/desktop -n 10
```

The CLI emits a `no_results_multiterm` hint when this is the likely failure.

## Query efficiency

Query cheaply; quotas are cost-based, and lexical and semantic have separate limits:

1. Scope before broadening: add `-R`, `org:`, `path:`, `language:`, or a more distinctive literal before raising `-n`.
2. Use the default result limit. Set `-n` only when the task needs a specific bound; repeated searches just to raise the limit cost more server work.
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
| `1`  | Setup, API, network, validation, or output error. Command errors use a `{"type":"error", ...}` record on stdout in JSONL mode; human formats and early setup failures use stderr |
| `2`  | CLI argument parse error on stderr |

Zero results is not a failure. Do not wrap calls in `|| true` or redirect stderr with `2>&1`; a non-zero exit is real and worth reading.

## Rules

- On a 429, honor the error's `retry_after_seconds` once with a cheaper query, then stop and report. Lexical and semantic limits are separate.
- Pair `--semantic` with `--auto-index` on repos that may not be indexed yet, or expect a 404.
- The result cap is `-n` / `--limit`. `--max-results` is not a flag and exits 2 with a pointer.
- Prefer `jq` one-liners or reading the file over ad-hoc post-processing scripts.
- Supported hosts are `github.com` and Proxima data-residency tenants (`<tenant>.ghe.com`). Self-hosted GHES is out of scope — that hostname fails with `UnsupportedHost` before a request is made.
- `gh blackbird` can search external filesets for a local corpus that is not a GitHub repo. Load the `blackbird-fileset` skill for that workflow. Run `gh blackbird fileset --help` for the full lifecycle; don't reinvent it here.

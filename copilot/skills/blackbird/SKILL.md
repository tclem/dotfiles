---
name: blackbird
description: 'Use when reaching for `gh blackbird` (Blackbird code search) for cross-repo lexical, symbol, or semantic search on GitHub — finding callers, ownership, or how systems work without cloning.'
---

# Blackbird Search

`gh blackbird` is a superset of grep for indexed GitHub code. Use it when the question is bigger than a local checkout: multi-repo scope, GitHub code-search qualifiers (`language:`, `path:`, `symbol:`), language-aware symbol lookup, or vector search over embeddings. If the needed repos are checked out locally and the task is exhaustive, use `rg`.

## Not exhaustive

`gh blackbird` is more like Google than grep: it returns top-ranked results capped by `-n` (defaults 25 lexical, 10 semantic), not every match. Treat output as a ranked sample, never as a complete set. **If you need every occurrence - for a refactor, a security sweep, a "did we miss any callers" check - clone the repo and use `rg` on the checkout.** That is the only tool that promises exhaustiveness here.

## When to use

- Multiple repos in one query, no cloning.
- "Where is symbol X defined?" or "where are likely callers?" - language-aware search beats regex for discovery.
- Ownership discovery: "where does X live?", "which repo owns X?", "how do clients integrate with X?"
- Conceptual / natural-language questions ("how does token resolution work in service Y?") - vector search over embeddings, not pattern matching.
- Lexical queries that benefit from GitHub code-search qualifiers (`language:rust`, `path:**/migrations/`, `symbol:Foo`, `repo:owner/name`).
- Broad lexical queries on large local repos where ranked discovery is enough and Blackbird's index beats a cold `rg` scan.
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

## Query efficiency

Blackbird quotas are cost-based, not just request-count based. Lexical and semantic have separate quota buckets, and expensive queries consume more quota. Treat every broad search as spending a shared budget.

Use the cheapest useful query first:

1. Prefer local `rg` when the repo is already checked out and the scope is local.
2. Prefer lexical discovery over semantic when you have concrete identifiers, strings, paths, routes, docs names, config keys, package names, or repo names.
3. Prefer `--symbol` for exact name lookup instead of broad lexical regexes.
4. Scope before broadening: add `-R owner/repo`, `path:`, `language:`, package/service names, or a distinctive quoted string before increasing `-n`.
5. Start with a small cap (`-n 5` or `-n 10`) for discovery. Increase only if the first page proves the query is correctly scoped and still lacks the needed evidence.
6. Avoid broad `OR` queries across large repos as a first move. Split them into narrower searches so one expensive term does not burn quota and flood output.
7. Do not run lexical and semantic back-to-back "just in case." Pick one mode from the evidence, then switch only when the result shows the mode is wrong.
8. Use `--for-llm` by default when an agent is parsing the output; it bounds response size so a single broad query can't flood context.
9. Clip pathological snippets with `-M N` (e.g. `-M 200`) when results include minified JS, generated code, or other very long lines.
10. Stop searching once you have a canonical file, owner repo, route, schema, doc, or wrapper symbol to read. Reading one result is cheaper and more reliable than another broad search.

If a query returns noisy results, make it cheaper before retrying: lower `-n`, add repo/path/language qualifiers, add `-M` to clip long lines, search a more distinctive literal, or search the wrapper/symbol that appeared in the first results.

## Discovery before semantic

For ambiguous cross-repo questions, first find the owner repo/component. If the user asks "how do I integrate with X's API?" or "where does X live?", do **lexical discovery** for proper nouns, service names, repo names, docs references, config keys, routes, or schema names across likely repos/orgs before semantic search.

Semantic search is good for "within this repo, explain this concept." It is a poor first move for "find the repo/component that owns this concept" because `--semantic` is single-repo scoped and searching the wrong repo returns plausible but irrelevant neighbors.

Example progression for "How do I integrate with Octokit authentication?":

1. Lexical discovery: search `octokit authentication` in likely repos such as `octokit/octokit.rb`, `octokit/rest.js`, or broader org scope if available.
2. Inspect hits for the canonical owner repo, docs, routes, schema, or README references.
3. Once the owner repo is identified, read docs/README/routes/schema files first.
4. Lexical-search auth/API terms inside the owner repo: `JWT`, `token`, `Authorization`, `GraphQL`, `curl`.
5. Use semantic search inside the owner repo only if docs are absent or the conceptual flow remains unclear.
6. Use symbol search only after concrete class/module/function names appear.

After finding a likely canonical doc, route file, schema, or README, stop broad search and read it. Do not keep searching when the answer surface has been found.

## Caller tracing

"Who calls X?", "all callers of X?", and "what is causing this call in production?" are caller-enumeration tasks. Use `gh blackbird` for discovery across repos you do not have locally. If the relevant repo is checked out, use local `rg` for exhaustive caller work.

Caller tracing ladder:

1. Start at the callee definition: proto method, interface, endpoint, route, or function.
2. Identify generated clients, wrappers, SDK helpers, or service-specific abstractions around that call.
3. Search the wrapper method first; real callers often use `Client.search` or `ApiClient#do_request`, not the raw request type.
4. Search direct usage next: request/response types, generated client methods, concrete HTTP/Twirp/gRPC paths, endpoint strings.
5. Separate production callsites from tests, fakes, fixtures, generated code, and docs.
6. For operational questions, use code search to enumerate possible callers, then telemetry/logs/metrics to rank active production callers.

For service/RPC endpoints, search all of these when available:

- Proto or IDL method name.
- Generated client method.
- Concrete HTTP/Twirp/gRPC path.
- Language-specific wrapper names.
- Fully-qualified request/response type names.

Generic names create false positives. Scope aggressively with repo/org plus package/API names and inspect paths before drawing conclusions. Prefer `SomeService::Client.count`, `/twirp/example.v1.QueryAPI/Count`, or `Example::V1::CountRequest` over a bare `CountRequest`.

Once a wrapper is identified, stop broad search and search that wrapper symbol/string. Wrapper callers are usually the real integration points.

## Output for agents

Three output tiers, in order of preference for agent use:

1. **`--for-llm`** - default for agents. Sugar for `--max-tokens 4000 --format jsonl`: server picks high-density regions under a token budget and emits JSONL. Use this whenever an agent will consume the output.
2. **`--json`** (= `--format jsonl`) - JSONL without the token cap. Use when you specifically need grep-style snippet control (`-A`/`-B`/`-C`/`-M`/`--full-snippet`), a non-4000 `--max-tokens N` budget, or the response set the `results_incomplete: true` meta flag on a previous `--for-llm` run of the same query. Don't switch pre-emptively "in case results are too short."
3. **`pretty`** - humans only. Never grep or parse it.

`--for-llm` and the grep-style snippet flags (`-A`/`-B`/`-C`/`-M`/`--full-snippet`) are mutually exclusive — the LLM mode picks its own dense regions, so you choose one strategy or the other:

- **Token-budgeted** (`--for-llm`): let the server decide what's relevant. Best default.
- **Grep-style** (`--json` + `-C N` / `-M N` / `--full-snippet`): explicit line context and width clipping. Use when you need predictable surrounding lines or to clip minified/generated lines from blowing context. These flags affect JSONL output as of v0.2.0 ([#14](https://github.com/github/gh-blackbird/pull/14)).

```sh
# Default agent invocation: token-capped JSONL
gh blackbird search 'TokenResolver language:rust path:src/auth' -R owner/name --for-llm

# Grep-style: explicit context + width clip (requires --json, not --for-llm)
gh blackbird search 'parseURL' -R a/b -R c/d --json -C 3 -M 200

# Exact symbol lookup (language-aware)
gh blackbird search --symbol parse_url -R owner/name --for-llm

# Semantic / conceptual (single repo, may need indexing)
gh blackbird search --semantic "how does token resolution work" -R owner/name --auto-index --for-llm -n 5

# External fileset (dotcom only)
gh blackbird search 'pattern' --fileset my-corpus --for-llm -n 10

# Custom token budget (overrides --for-llm's 4000)
gh blackbird search 'pattern' -R owner/name --json --max-tokens 8000
```

Cap results with `-n` when scoping a broad query. Defaults: 25 lexical, 10 semantic. For agent discovery, prefer `-n 5` or `-n 10` unless you already know the query is narrow.

## Rate limits and retries

429s mean the current quota bucket is exhausted or the query spent too much of it. Because lexical and semantic have different cost buckets, do not assume a semantic retry tells you anything about lexical quota, or vice versa.

When using `--json`, errors are JSONL too:

```json
{"type":"error","code":"rate_limited","status":429,"retry_after_seconds":30,"rate_limit_reset_epoch_seconds":1778990400,"guidance":"Back off before retrying; honor retry_after_seconds or rate_limit_reset_epoch_seconds when present."}
```

Handle 429s deliberately:

1. If `retry_after_seconds` is present and short enough to wait in the current tool run, wait that long plus a small cushion, then retry once.
2. If only `rate_limit_reset_epoch_seconds` is present and the reset is soon, wait until reset plus a small cushion, then retry once.
3. Before retrying, make the query cheaper unless the exact same query is necessary: reduce `-n`, add `-R`/`path:`/`language:`, split broad `OR`s, or switch from semantic to lexical when you have concrete terms.
4. If the wait is long, the reset time is missing, or the retry also returns 429, stop and tell the user the query hit Blackbird rate limits. Include the mode (lexical or semantic), any retry/reset value, and the cheaper query you would try next.
5. Do not spin on 429s. One intentional retry is enough for an agent unless the user explicitly asks to keep waiting.

## Rules

- Default agent invocation is `--for-llm` (token-capped JSONL). Drop to `--json` only when (a) you need grep-style snippet flags `-A`/`-B`/`-C`/`-M`/`--full-snippet`, which are mutually exclusive with `--for-llm`; (b) a previous `--for-llm` run on the same query returned `results_incomplete: true`; or (c) you need a specific non-4000 `--max-tokens` budget. Never grep `pretty`.
- `--semantic` accepts at most one `-R`. Lexical accepts many.
- Pair `--semantic` with `--auto-index` against repos that may not be indexed yet, otherwise expect a 404.
- Use `--symbol` for name lookup; do not regex around it.
- Use `--semantic` for conceptual questions only after the repo scope is known; do not lexical-search a paraphrase inside a known repo when semantic would answer the concept better.
- For ownership discovery, lexical-search proper nouns and concrete identifiers first. Do not start with semantic in a guessed repo.
- For "all callers" questions, use local `rg` on checked-out repos whenever possible. Do not present ranked Blackbird results as exhaustive.
- Spend quota intentionally: start narrow and low-`-n`, then broaden only when the first results justify it.
- On JSONL errors with `code=="rate_limited"`, honor retry/reset metadata once; otherwise report the rate limit instead of looping.
- Do not duplicate case variants unless the first result suggests case matters; code search for `octokit` can already find `Octokit`.
- Prefer simple `jq` one-liners or reading key files over opaque ad-hoc post-processing. Avoid Python summarizers unless there is a real need.
- Do not pass `--lab` (staff-only no-op).
- No GHES. No filesets on `*.ghe.com`.
- Snippet context (`-C/-A/-B`, `--full-snippet`) and width clipping (`-M`) work with `--json` JSONL output as of v0.2.0, but are mutually exclusive with `--for-llm`. Pick the LLM mode or the grep-style mode, not both.

## Common mistakes

- **Reaching for `rg` reflexively** when the right tool is `--symbol`, `--semantic`, or a cross-repo lexical query.
- **Approximating symbol search with a regex** when `--symbol` exists.
- **Starting semantic search in a guessed repo** when the real task is ownership discovery — find the owner repo lexically first.
- **Continuing broad search after finding the canonical doc/route/schema/README.** Read it instead of running another query.
- **Searching only raw request types** and missing the wrapper methods production callers actually use.
- **Claiming "all callers"** from top-N Blackbird results without falling back to local `rg` or another exhaustive source.
- **Retrying a 429 immediately**, repeatedly, or with the same expensive query when retry/reset metadata says to wait.
- **Treating Blackbird results as exhaustive** in any mode — it is top-N ranked, not every match.

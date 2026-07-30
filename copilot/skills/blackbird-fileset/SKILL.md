---
name: blackbird-fileset
description: 'Use when ingesting, refreshing, listing, searching, or deleting a local corpus with Blackbird code search and `gh blackbird search --fileset`.'
---

# Managing External Filesets

Use external filesets for code-like corpora that are on disk but are not indexed as GitHub repositories. This skill owns the fileset lifecycle; use `blackbird` for general GitHub code-search strategy.

## Canonical workflow

From the corpus directory, keep ingestion and search on the same inferred name:

```sh
gh blackbird fileset ingest --dry-run
gh blackbird fileset ingest
gh blackbird search --fileset --semantic "where is request throttling implemented?"
gh blackbird search --fileset 'rate_limit'
```

Bare `fileset ingest` recursively ingests the current directory and names the fileset after its canonical basename. Bare `search --fileset` independently infers the current directory basename. Run both from the same directory, or pass an explicit pair:

```sh
gh blackbird fileset ingest ./vendor/widget --name widget-src
gh blackbird search --fileset widget-src --semantic "how are retries bounded?"
```

## Search behavior

- Use lexical fileset search for a known token and `--semantic` for a concept. External fileset search rejects `--symbol`, `--auto-index`, and `--experiment`.
- When piped, lexical fileset search emits JSON and implicitly requests snippets within a 4000-token budget. `--max-tokens N` overrides that lexical budget and has no effect on semantic search.
- External JSON is one complete response object, not the per-record JSONL emitted by internal search. `--format oneline` falls back to `pretty`. `-A`/`-B`/`-C`/`-M`/`--full-snippet` do not shape external results and disable the implicit token budget.

## Ingest and refresh

- Run `--dry-run` first for an unfamiliar or large tree. It walks, filters, hashes, and reports the checkpoint without making HTTP calls.
- Re-running ingest refreshes the named fileset. The client reconciles hashes and uploads only changed documents; an unchanged checkpoint exits successfully as already up to date.
- The walk honors `.gitignore` and skips `target`, `node_modules`, `.git`, `data`, and `.jj`. Linguist filters binary, generated, and vendored content. Non-UTF-8 paths are skipped, and one fileset is capped at 200,000 ingestable files.
- An interrupted ingest leaves resume state under `~/.config/gh/blackbird/`. Re-run the same command to resume. Use `--restart` only when the stored ingest expired or the server aborted it; server ingest state lasts about two hours.
- After finalization, semantic search may take about 10 seconds to see the checkpoint. The CLI reports a short-lived `search_hint` but does not pass it to search. Retry after a few seconds instead of re-ingesting.

## Ownership and cleanup

Filesets belong to the authenticated GitHub actor:

```sh
gh blackbird fileset list --json
gh blackbird fileset delete widget-src
gh blackbird fileset delete widget-src --yes
```

List before diagnosing a 404 or deleting by name. Deletion is irreversible; `--yes` is required when stdin is not interactive.

## Common mistakes

- Do not treat a just-finalized semantic miss as proof the content was filtered or absent. Wait for checkpoint visibility, then retry once.
- Do not delete and recreate a fileset to update it. Ingest the same name and let checkpoint reconciliation upload the delta.

## Remote Code Discovery

Prefer Blackbird for remote source-code search.

Load the `blackbird` skill before using Blackbird. Use `gh blackbird search --semantic --remote-only` to search one GitHub repository's indexed default branch using a natural-language description. The current repository is the default; `-R owner/name` selects another. Workspace changes are excluded.

Use `gh blackbird search --remote-only` to search indexed GitHub code for exact text, identifiers, symbols, paths, or regular expressions. It returns ranked files with matching line numbers and a short preview. Terms are ANDed; use `OR` or `NOT`, quote exact phrases, or write `/regex/`. Scope with `owner:`, `enterprise:`, or `(repo:a/b OR repo:c/d)`. Filter with `path:`, `content:`, `language:`, `symbol:`, or `def:`.

Use `view` for local files and GitHub MCP `get_file_contents` for remote files pinned to a ref or SHA. Do not use GitHub's legacy code search: GitHub MCP `search_code`, `gh search code`, or the code-search REST/GraphQL endpoints.

## Remote Code Discovery

Use `gh blackbird search --semantic --remote-only` to search one GitHub repository's indexed default branch using a natural-language description. Use it for locating or understanding code, even with a known identifier. The current repository is the default; `-R owner/name` selects another. Workspace changes are excluded.

Use `gh blackbird search --remote-only` to search indexed GitHub code for exact text, identifiers, symbols, paths, or regular expressions. It returns ranked files with matching line numbers and a short preview. Terms are ANDed; use `OR` or `NOT`, quote exact phrases, or write `/regex/`. Scope with `owner:`, `enterprise:`, or `(repo:a/b OR repo:c/d)`. Filter with `path:`, `content:`, `language:`, `symbol:`, or `def:`. Do not use the GitHub MCP `search_code` tool.

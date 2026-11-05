---
name: dd-pup
disabled: true
description: Use when querying Datadog with Pup or reviewing whether a proposed Pup command supports a Datadog workflow.
---

# Datadog with Pup

Use the official Pup CLI for Datadog work. Verify the exact command and its read/write behavior before running it; never infer that Pup has complete parity with another Datadog client.

## Workflow

1. Confirm `pup` is installed. If a command or subcommand is unfamiliar, inspect `pup --help` and `pup <group> --help` rather than guessing.
2. Keep the requested scope: use the stated org/site, query, and time window. If a needed value is missing, ask instead of broadening the query silently.
3. Prefer read-only commands and add `--read-only` when the selected command supports it. Do not create, update, delete, submit, post, or otherwise mutate Datadog state unless the user explicitly asked for that change.
4. Report the exact query and time window with findings. Distinguish an empty result from an access or command error.

## Common read workflows

- Metrics: `pup metrics query` for time series; `pup metrics list` or `pup metrics search` to discover metrics.
- Logs: `pup logs search` and `pup logs aggregate`.
- If a logs query warns that Flex storage is unavailable and falls back to indexed logs, report that limitation; a successful empty result does not establish that the broader Flex-backed time range is empty.
- Traces and spans: `pup traces search`, `pup traces get`, and `pup traces aggregate`.
- Events: `pup events list`, `pup events search`, and `pup events get`. Pup 2.4.1 has no `events aggregate` command; do not substitute a different dataset's aggregation or claim parity.
- Dashboards, notebooks, monitors, and incidents: inspect their group help, then use the available list/search/get operations for the requested resource.

Use `--help` to confirm options for time ranges, filters, pagination, output, and read-only mode. Do not put credentials in command arguments or output.

## Authentication and gaps

Do not run `pup auth login`, refresh credentials, or trigger Keychain/OAuth prompts to test access. If a query lacks credentials, stop and report that authentication requires the user's action. `DD_TOKEN_STORAGE=file pup auth status` avoids Keychain but checks only file-backed credentials; a negative result does not establish that no other credential store is configured.

If Pup does not expose the requested operation, say so and use an already-authorized alternative only if it remains available and the user has not asked to retire it. Do not claim that installing Pup proves live account access or complete MCP parity.

---
name: dd-pup
description: Use when querying Datadog with Pup, checking Pup authentication safely, or reviewing whether a proposed Pup command supports a Datadog workflow.
---

# Datadog with Pup

Use Pup for the Datadog workflows observed in the session history below. This is a deliberately bounded migration guide, not a catalog of Pup features or a claim of full MCP parity.

## Workflow

1. Keep the requested scope: use the stated service, metric, filters, and time window. If a needed value is missing, ask instead of broadening the query silently.
2. Prefer read-only commands and add `--read-only` where supported. Do not change credentials or mutate Datadog state unless the user explicitly asked.
3. Use `pup <group> --help` to verify options before relying on an unfamiliar flag. Report the query and time window, and distinguish an empty result from an access or command error.

## Observed workflows

| Observed Datadog work | Pup command or gap |
|---|---|
| Metric queries, metric discovery, and metric context | `pup metrics query`, `pup metrics search`, and `pup metrics metadata get`. Metadata lookup is not verified as a replacement for context responses containing scoped tag values or related assets. |
| Log search | `pup logs search`. If Flex is unavailable and Pup falls back to indexed logs, report that the result may not cover the full requested range. |
| Span search/aggregation and trace retrieval | `pup traces search`, `pup traces aggregate`, and `pup traces get`. |
| Event search and aggregation | `pup events search` is available; Pup 2.4.1 has no `events aggregate` command. Keep the existing alternative for event aggregation. |
| Monitor search, dashboard retrieval, and notebook retrieval | `pup monitors search`, `pup dashboards get`, and `pup notebooks get`. The observed dashboard-search operation has no corresponding Pup search subcommand; do not treat `dashboards list` as equivalent without verifying the requested behavior. |
| APM change stories | `pup change-stories list --service <SERVICE> --from <START> --to <END>`. |
| Dashboard upsert and widget guidance | Pup has dashboard create/update and widget-schema commands, but these do not establish parity with the MCP widget expert. Mutate dashboards only when explicitly requested. |
| Datadog MCP skill listing/loading | This skill provides focused query guidance; it does not replace the MCP's Datadog skill registry. |

## Authentication and reporting gaps

Do not run `pup auth login`, refresh credentials, or trigger Keychain/OAuth prompts to test access. If a query lacks credentials, stop and report that authentication requires the user's action. Run queries with Pup as configured, e.g. `pup metrics query --read-only ...`; never set `DD_TOKEN_STORAGE` or otherwise override token storage for queries or to judge access. Forcing file storage hides the configured credentials and reports a false authentication failure. Judge access by a real read-only query. Only when the user requests a status check but forbids Keychain, use `DD_TOKEN_STORAGE=file pup auth status`; it checks only file-backed credentials, so a negative result does not mean Datadog access is missing.

For a missing or only partially matched workflow above, state the gap and use an already-authorized alternative if available. Do not infer parity from a similarly named command or from Pup being installed.

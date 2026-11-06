---
name: azure-kusto
disabled: true
description: Use when reviewing Azure Data Explorer/Kusto REST client changes, querying Kusto clusters, or inspecting their databases, tables, and schemas.
---

# Azure Kusto

Use Kusto REST for KQL; `az kusto` manages resources, not queries. In reviews, propose only the reported defect's fix; don't add independent endpoint, response, result-shaping, or test changes. Tests are separate work unless requested or needed to verify that defect.

- Use `az rest --resource https://api.kusto.windows.net` with the existing Azure CLI session. Never print tokens or start sign-in; report missing or rejected credentials as a blocker.
- Use only user-supplied or read-only-discovered cluster URIs and databases. Use Azure CLI for resource inventory and Redis, and Microsoft Learn for Azure docs.
- POST KQL to `/v2/rest/query`; POST `.show` metadata and schema commands to `/v1/rest/mgmt`. Set `x-ms-readonly: true`; run only reads unless the user specifically authorizes a change.
- Bound queries with time filters, `project`, and `take`.
- Surface non-2xx errors. For v2, require final `DataSetCompletion.HasErrors` to be false and return only `PrimaryResult`. For v1, inspect `QueryStatus`; severity <= 2 indicates failure. HTTP 200 alone is insufficient.

See [Kusto REST authentication](https://learn.microsoft.com/en-us/kusto/api/rest/authentication?view=azure-data-explorer), [request format](https://learn.microsoft.com/en-us/kusto/api/rest/request?view=azure-data-explorer), [v1 response](https://learn.microsoft.com/en-us/kusto/api/rest/response?view=azure-data-explorer), and [v2 response](https://learn.microsoft.com/en-us/kusto/api/rest/response-v2?view=azure-data-explorer).

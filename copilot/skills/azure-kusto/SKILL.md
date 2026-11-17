---
name: azure-kusto
description: Use when querying Azure Data Explorer/Kusto clusters or inspecting databases, tables, and schemas.
---

# Azure Kusto

Use Kusto REST for KQL; `az kusto` manages resources, not queries.

- Use `az rest --resource https://api.kusto.windows.net` with the existing Azure CLI session. Never print or persist tokens or start sign-in; report missing or rejected credentials as a blocker.
- Use only user-supplied or read-only-discovered cluster URIs and databases. Use Azure CLI for resource inventory and Redis, and Microsoft Learn for Azure docs.
- POST KQL to `/v2/rest/query` with `db` and `csl` in the JSON body; POST `.show` metadata and schema commands to `/v1/rest/mgmt`. Set `x-ms-readonly: true`; run only reads unless the user specifically authorizes a change.
- Bound queries with time filters, `project`, and `take`; return only the necessary columns and rows.
- Surface non-2xx errors. For v2, require final `DataSetCompletion.HasErrors` to be false and return only `DataTable` frames with `TableKind: PrimaryResult`. For v1, inspect `Tables` and `QueryStatus`; severity <= 2 indicates failure. HTTP 200 alone is insufficient; report unexpected, incomplete, or error-bearing responses rather than presenting partial results as successful.

See [Kusto REST authentication](https://learn.microsoft.com/en-us/kusto/api/rest/authentication?view=azure-data-explorer), [request format](https://learn.microsoft.com/en-us/kusto/api/rest/request?view=azure-data-explorer), [v1 response](https://learn.microsoft.com/en-us/kusto/api/rest/response?view=azure-data-explorer), and [v2 response](https://learn.microsoft.com/en-us/kusto/api/rest/response-v2?view=azure-data-explorer).

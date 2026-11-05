---
name: azure-kusto
disabled: true
description: Use when querying Azure Data Explorer/Kusto clusters or inspecting databases, tables, and schemas through Azure CLI and Kusto REST.
---

# Azure Kusto

Use the Kusto REST API for data-plane KQL. `az kusto` manages Azure resources; it does not execute KQL.

## Authenticate and route

- Use `az rest` with `--resource https://api.kusto.windows.net`; it attaches the token from the existing Azure CLI session. Never print or persist tokens. Do not start an interactive sign-in flow; if cached credentials fail, report the blocker.
- Use a cluster URI and database supplied by the user or discovered through read-only Azure CLI resource listing. Never guess a target.
- Keep this skill focused on Kusto. Use Azure CLI read-only commands for resource inventory and Redis, and Microsoft Learn or documentation search for Azure docs and best practices.

## Read-only requests

- POST KQL queries to `<cluster-uri>/v2/rest/query`; send `db` and `csl` in the JSON body.
- POST `.show` metadata commands to `<cluster-uri>/v1/rest/mgmt`; use it for table/database discovery and `.show table <name> schema as json`.
- Set `x-ms-readonly: true`, but still send only queries and `.show` commands. Do not run resource or data mutations unless the user explicitly authorizes the specific change.
- Bound queries with appropriate time filters, `project`, and `take`; return only the columns and rows needed.

## Check every response

- Surface non-2xx errors. Do not retry authentication or treat 401/403 as a reason to sign in.
- HTTP 200 alone does not mean a query succeeded. For v2 responses, inspect the final `DataSetCompletion` frame and require `HasErrors: false`; use only `DataTable` frames with `TableKind: PrimaryResult`.
- For v1 management responses, inspect `Tables` and `QueryStatus`; severity values of 2 or lower indicate failure.
- If the response shape is unexpected, incomplete, or reports errors, say so plainly and do not present partial results as successful.

References: [Kusto REST authentication](https://learn.microsoft.com/en-us/kusto/api/rest/authentication?view=azure-data-explorer), [request format](https://learn.microsoft.com/en-us/kusto/api/rest/request?view=azure-data-explorer), [v1 response](https://learn.microsoft.com/en-us/kusto/api/rest/response?view=azure-data-explorer), and [v2 response](https://learn.microsoft.com/en-us/kusto/api/rest/response-v2?view=azure-data-explorer).

When reviewing Kusto REST feedback, keep proposed changes limited to the defect raised. Do not add adjacent endpoint, response-parsing, or result-shaping work unless it is required to fix that defect.

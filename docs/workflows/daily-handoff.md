Help me author a daily handoff for my team (blackbird). I will paste this in slack so present as a markdown block that I can copy easily. I use :merged: and :review: and I like to list any meetings or conversations I've had first (but i'll add this manually). You MUST use the syntax shown in the example below for markdown links. Here's an example handoff:

```
Handoff:
* A number of random 1:1s and meetings

* Working on [Migrate the legacy geyser code search api to Rust](@github/blackbird/pull/13868 ) and got a few PRs deployed today like: [Evict failing hosts from DSA routing on query failure](@github/blackbird/pull/14285 ). Work on some better metrics tags in:
* :review: Fix client_application metric label cardinality: @github/blackbird/pull/14364 :rev
* :review: Add num_unavail_shards metrics: @github/blackbird/pull/14362
* I'm also exploring service proxy support for geyser in proxima in @github/github/pull/427478 and @github/blackbird/pull/14287
* traffic is running to the new service at 0.01% - i'd like to see those additional metric fixes before moving further.

* In the [LLM query rewrite experiment](https://github.com/github/blackbird/pull/14283), I'm debugging why the mcp server can't talk to blackbird, this is blocking further progress. I did merge a few fixes, working with @sammorrowdrums on the open ones below.
* :merged: Add blackbird search URLs for proxima: https://github.com/github/github-mcp-server-remote/pull/793
* :merged: Wire BLACKBIRD_MW_QUERY_SERVICE_HMAC_KEY from vault-secrets: https://github.com/github/github-mcp-server-remote/pull/785
* :merged: Improve lexical_code_search tool description and bump result limit: https://github.com/github/github-mcp-server-remote/pull/783
* :review: Add ServiceMeshConfig for dotcom (production/staging): https://github.com/github/github-mcp-server-remote/pull/794
* :review: Route blackbird traffic over the service mesh in production: https://github.com/github/github-mcp-server-remote/pull/784

* github-app progress in :thread:
```

I include only github-app PRs in the thread b/c that's a side project right now so generate a separate message for that.

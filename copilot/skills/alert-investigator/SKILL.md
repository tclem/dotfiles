---
name: alert-investigator
description: Use when investigating an alert, monitor, incident, error spike, degraded service, or production anomaly, and the repository has no incident-investigation skill of its own.
---

# Investigate Alert

Diagnose what triggered an alert or production anomaly, gather evidence, and produce a concise report with uncertainty and next actions.

## Inputs

Accept any of:

- Datadog monitor URL or ID
- Datadog incident URL or ID
- GitHub issue URL or `owner/repo#number`
- Sentry issue URL or ID
- Error message, service name, metric name, dashboard link, trace ID, or freeform alert text

If the input is ambiguous, ask for the missing identifier or affected service.

## Workflow

1. **Parse the input.** Extract service names, environment, monitor IDs, issue numbers, trace IDs, error messages, and timestamps.
2. **Load domain guidance before querying.** If Datadog tools are available, load the relevant Datadog skill guide before using logs, metrics, traces, RUM, incidents, or dashboards.
3. **Read source context.**
   - For GitHub issues, read the issue body and comments.
   - For Datadog monitors/incidents, read the monitor query, thresholds, status, timeline, tags, and linked resources.
   - For Sentry issues, read stack traces, affected releases, frequency, users, and linked traces when tools are available.
4. **Define the time window.** Start with one hour before trigger through now for active alerts. For resolved alerts, include at least one hour before trigger through one hour after recovery. Expand if the first event is already anomalous.
5. **Gather telemetry.**
   - Metrics: triggering metric plus adjacent service, host, dependency, queue, database, cache, and saturation metrics.
   - Logs: error patterns, deploy/config messages, restarts, rate-limit or timeout messages, and changed volume.
   - Traces: slow or failed paths, upstream/downstream propagation, span errors, and outliers.
   - Events: deploys, feature flag changes, config changes, incidents, monitor state changes.
6. **Check dependencies.** Identify upstream callers and downstream services that could explain the symptom.
7. **Check code when useful.** Search for the metric, log message, route, error type, or stack frame. Explain how the relevant code path could produce the observed behavior.
8. **Correlate and conclude.** Align timestamps across sources. Separate evidence, hypothesis, and uncertainty.

## Report format

```markdown
# Alert Investigation: <name>

**Status:** <active/resolved/unknown>
**Window:** <start> to <end>
**Affected service/environment:** <service/env>
**Confidence:** <high/medium/low> - <why>

## Summary

<2-4 sentences: what happened, likely cause, impact, current state.>

## Evidence

| Source | Finding | Link/query |
|---|---|---|
| Metrics | <finding> | <dashboard/query> |
| Logs | <finding> | <query> |
| Traces | <finding> | <trace/query> |
| Code | <finding> | <file/function> |

## Timeline

| Time | Event | Source |
|---|---|---|
| <time> | <event> | <link/query> |

## Likely cause

<Primary hypothesis and why it fits the evidence.>

## Alternatives considered

<Other plausible causes and why they are less likely or unproven.>

## Recommended actions

1. **Immediate:** <mitigation or next diagnostic step>
2. **Follow-up:** <bug, monitor, runbook, or investigation item>
```

Omit sections that do not apply, but every claim should be verifiable through a link, query, trace ID, issue, or code reference.

## Guidelines

- Follow the data; do not force a preferred explanation.
- Document uncertainty explicitly.
- Prefer aggregate queries for scale questions and raw events for examples.
- Include enough query detail that another engineer can reproduce the finding.
- Do not post findings to GitHub unless the user asks; if posting, follow the GitHub Posting Protocol in the global instructions.


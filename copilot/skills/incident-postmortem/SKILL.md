---
name: incident-postmortem
description: Use when assembling, updating, or reviewing an incident postmortem, and the repository has no postmortem skill of its own.
---

# Incident Postmortem

Assemble an evidence-backed, blameless postmortem. Preserve human responder context, fill gaps with telemetry, and identify actionable repair items.

## Inputs

Accept any of:

- GitHub issue URL or `owner/repo#number`
- Datadog incident URL or ID
- Incident document, timeline, Slack excerpt, alert issue, dashboard, or freeform notes

If no source is provided, ask whether to update an existing postmortem or draft a new one.

## Workflow

1. **Read the source.** Gather issue body, comments, incident timeline, linked alerts, dashboards, runbooks, and responder notes.
2. **Identify known facts and gaps.** Preserve filled-in human-written sections. Mark missing impact, timeline, mitigation, root cause, response effectiveness, or repair items.
3. **Set the investigation window.** Use two hours before the first known symptom through two hours after recovery unless the data suggests a wider window.
4. **Gather evidence.**
   - Alerts/events: state changes, pages, deploys, config changes, mitigations.
   - Metrics: user impact, service health, saturation, dependency health, recovery confirmation.
   - Logs/traces: error propagation, latency paths, exceptions, failed dependencies.
   - Code: relevant paths for root cause and repair items.
5. **Build the timeline.** Use UTC unless the existing template says otherwise. Cross-check timestamps across sources and flag discrepancies.
6. **Analyze cause.** Separate trigger, proximate cause, systemic cause, and recovery factors.
7. **Assess impact.** State customer/user impact first. If there was no impact, explain what contained it.
8. **Create repair items.** Each item should have a concrete owner-ready outcome, acceptance criteria, and evidence link.
9. **Draft the update.** Supplement existing content instead of overwriting firsthand responder notes.
10. **Review before posting.** Present the proposed issue/comment update to the user before applying it.

## Optional Datadog notebook

Create a Datadog notebook when the incident has meaningful telemetry evidence or when the user asks for one. Include:

- incident summary and time window;
- key metrics and log queries;
- trace examples or links;
- timeline and recovery evidence;
- query documentation sufficient for another engineer to reproduce the analysis.

Link the notebook from the postmortem draft.

## Postmortem structure

```markdown
# Incident Postmortem: <title>

## Impact / Executive Summary

<Who was affected, for how long, severity, current state.>

## Timeline

| Time (UTC) | Event | Source |
|---|---|---|
| <time> | <event> | <link/query> |

## Mitigation and Recovery

<What stopped the impact and how recovery was verified.>

## Root Cause Analysis

**Trigger:** <external event/change>
**Proximate cause:** <immediate failure mode>
**Systemic cause:** <design/process/monitoring gap>

## Response Effectiveness

**Went well:** <evidence-backed notes>
**Could improve:** <evidence-backed notes>
**Where we got lucky:** <optional>

## Repair Items

| Item | Outcome | Evidence |
|---|---|---|
| <title> | <acceptance criteria> | <link/query/code> |
```

## Guidelines

- Be blameless: describe system behavior, not personal fault.
- Every factual claim needs a source link, query, trace ID, log sample, dashboard, issue, or code reference.
- Do not overwrite human-written incident responder content unless the user explicitly asks.
- Distinguish confirmed facts from hypotheses.
- If posting to GitHub, follow the GitHub Posting Protocol in the global instructions.


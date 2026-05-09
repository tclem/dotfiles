---
name: debugging-systematically
description: Use when investigating a bug, failing test, production issue, unexpected behavior, flaky behavior, regression, or unclear root cause.
---

# Debugging Systematically

Find the root cause before fixing symptoms.

## Process

1. Capture the observed behavior, expected behavior, reproduction, scope, and when it started.
2. Reproduce the issue or find direct evidence. If you cannot reproduce it, narrow the missing condition instead of guessing.
3. Read the relevant code path and data flow.
4. Form a hypothesis that explains all known facts.
5. Test the hypothesis with the smallest useful experiment: targeted test, log query, trace, debugger, or local command.
6. Fix the root cause, not just the visible symptom.
7. Verify the original symptom is gone and related behavior still works.

## Rules

- One hypothesis at a time.
- Prefer evidence over intuition.
- Do not patch around unknown causes.
- If new evidence contradicts the hypothesis, update the model before editing more code.


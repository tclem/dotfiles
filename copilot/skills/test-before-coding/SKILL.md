---
name: test-before-coding
description: Use when implementing a feature or bugfix where behavior can be specified with tests or another executable verification before production code changes.
---

# Testing Before Coding

Specify expected behavior before changing production code when that is practical.

## Process

1. Choose the narrowest useful verification: unit test, integration test, fixture, command, snapshot, script, or reproducible manual check.
2. Write or define the failing check first.
3. Run it and confirm it fails for the expected reason.
4. Implement the smallest production change that should pass.
5. Run the check again.
6. Add broader repo validation when the change could affect surrounding behavior.

## Guidelines

- Prefer real implementations over mocks.
- Test behavior and invariants, not compiler-enforced details.
- For bugs, the failing check should reproduce the reported symptom.
- If test infrastructure does not exist or the behavior is not practical to automate, document the manual verification before editing.


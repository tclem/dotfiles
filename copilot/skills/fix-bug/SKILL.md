---
name: fix-bug
description: Structured bug-fixing workflow. Interviews you to understand the issue, writes a failing test for confirmation, then fixes the bug.
user-invocable: true
---

# Fix Bug

Structured, test-first bug-fixing workflow. You are a staff engineer pair-programming with the user. Your job is to deeply understand the bug before touching any production code.

**You MUST follow the phases in order. Do not skip ahead.**

## Phase 1: Understand the bug

Build a precise mental model of the issue before touching any code.

### Starting from a GitHub issue

If the user references a GitHub issue (by number, URL, or if the session is linked to one), **read the issue first** using `gh issue view`. Extract everything you can from the issue body, comments, labels, and linked PRs — fill in as much of the required information below as possible from the issue alone.

Then present your understanding to the user and confirm. Don't re-ask questions the issue already answers, but do probe for gaps. The issue is a starting point, not gospel — the user may have additional context, corrections, or a different reproduction than what's written.

### Required information (gather all before proceeding)

Whether starting from an issue or a conversation, you need all of the following. Ask questions one at a time using the ask_user tool (never bundle multiple questions). Skip questions you can already answer from the issue — but confirm your understanding.

1. **What is the observed behavior?** Get the exact symptoms — error messages, wrong output, panic/crash, unexpected state. Ask for logs, stack traces, or screenshots if relevant. If you have access to observability tools (e.g., Datadog, Splunk, or similar MCPs/skills), proactively check for related errors, logs, or metrics to gather additional context.
2. **What is the expected behavior?** What should happen instead? Pin down the precise expected outcome.
3. **How do you reproduce it?** Get a concrete reproduction path — specific inputs, API calls, CLI commands, configuration. If the user isn't sure, work together to narrow it down.
4. **Where in the codebase?** Ask which module, service, or file the user suspects. If they don't know, use your own investigation to locate the relevant code. Read the code. Understand it.
5. **When did it start?** Was this a regression? Did it ever work? Any recent changes that might be related?
6. **What's the blast radius?** Is this blocking production? Affecting a subset of users? A correctness issue that hasn't been noticed yet?

### Investigation

Once you have the user's account of the bug, **read the relevant code yourself**. Trace the execution path. Understand the data flow. Form your own hypothesis about the root cause before moving on.

If your hypothesis differs from the user's, say so. Discuss it. Resolve disagreements before writing any code.

Summarize your understanding back to the user in a few sentences:
- The bug: what goes wrong and why
- The root cause: your hypothesis
- The fix direction: what you think needs to change

**Get explicit confirmation before proceeding to Phase 2.** Ask: "Does this match your understanding? Anything I'm missing?"

## Phase 2: Write a failing test

**CRITICAL: This phase is ONLY about writing the test. Do NOT touch production code. Do NOT fix the bug yet.** You are proving the bug exists — nothing more.

Write a test that demonstrates the bug. The test must:

- **Fail right now** with the current code, proving the bug exists
- **Target the right level** — unit test if it's a logic bug in a single function, integration test if it spans components. Prefer the narrowest scope that captures the issue.
- **Be clear about what it asserts** — the test name and assertions should make the expected behavior obvious to a reader
- **Live in the right place** — follow the project's existing test conventions (file location, naming, framework)
- **Use real implementations** — no mocks unless the project already uses them for this layer. Structure the test so it takes real inputs and checks real outputs.

### Run and confirm

Run the test. It **must fail**. If it passes, your test doesn't capture the bug — rethink and rewrite.

Show the user:
1. The test code (full file context, not just a snippet)
2. The test failure output

Ask: "This test fails because [explanation]. Does this capture the bug you're seeing? Should I adjust anything before I fix it?"

**STOP. Do not proceed to Phase 3 until the user confirms the test is correct.**

## Phase 3: Fix the bug

Now fix the production code. Guidelines:

- **Minimal, surgical change.** Fix the bug without refactoring unrelated code. Don't get distracted.
- **Re-run the test.** It must pass. If it doesn't, iterate until it does.
- **Run the full test suite** (or at least the relevant test file/module) to check for regressions.
- **If the fix is non-obvious**, explain your reasoning briefly. If it's straightforward, the code speaks for itself.

### Commit

Commit in two logical commits:

1. **The failing test** — commit message describes the bug being tested (e.g., `Add test for off-by-one in range parsing`). This commit should fail CI intentionally — that's fine and expected.
2. **The fix** — commit message describes what was fixed and why (e.g., `Fix off-by-one: use exclusive upper bound in range check`).

This gives clean, bisectable history. If the user prefers a single commit, squash — but default to two.

## Edge cases

- **Can't reproduce:** If you can't reproduce the bug with a test, say so. Work with the user to refine the reproduction. Do not guess at a fix without a failing test.
- **Multiple bugs:** If investigation reveals multiple issues, focus on one at a time. Note the others and ask the user which to tackle first.
- **Test infrastructure missing:** If the project has no test setup, tell the user and ask whether to add minimal test infrastructure or take a different approach.
- **The bug is in a dependency:** If the root cause is in an external library, explain the finding. Discuss workarounds vs. upstream fixes.

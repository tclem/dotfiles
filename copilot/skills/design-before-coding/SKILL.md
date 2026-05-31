---
name: design-before-coding
description: Use when creating features, changing behavior, adding components, or making design-affecting implementation choices before editing code.
---

# Designing Before Coding

Understand the problem and choose an approach before changing files.

## Use this when

- The task adds behavior, UI, APIs, workflows, configuration, or architecture.
- Multiple reasonable approaches exist.
- The user is asking to "build", "add", "support", "change", or "refactor".

Skip for mechanical edits with no behavior or design choice.

## Process

1. Read the relevant repo docs, instructions, and nearby code.
2. Identify the job to be done, success criteria, constraints, and explicit non-goals.
3. If a choice materially changes behavior or architecture, ask one focused question. In autopilot, make the smallest reversible assumption and state it.
4. Compare 2-3 approaches when tradeoffs matter.
5. Pick the simplest complete design that fits existing patterns.
6. Only then edit code or write an implementation plan.

## Output

For small changes, keep the design to a short paragraph in your own working context. For larger changes, write a plan before editing.

Good designs name the files/components involved, data flow, error handling, validation, and what will prove the work is done.


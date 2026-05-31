---
name: authoring-design-docs
description: 'Use when authoring or substantially editing a design doc, architecture doc, or subsystem explanation — the "here''s what''s there and why" companion to an ADR''s terse decision record.'
---

# Authoring Design Docs

Design docs explain how a system actually works — its shape, mechanism, invariants, and trade-offs. They are the long-form complement to an ADR.

This is a user-level skill — repo-local conventions, when they exist, always win over the defaults here.

## ADR vs. design doc vs. SKILL vs. plan

These four artifacts pair up. Knowing which to reach for is half the work:

- **ADR** — the *decision*. Short, structured: Context / Decision / Consequences. Records "we chose X over Y, and these are the trade-offs we accepted." See `authoring-adrs`.
- **Design doc** — the *explanation*. Longer-form: how the system is shaped, why the pieces fit together, what the invariants are, diagrams and math where they help. Lives at `docs/<topic>-architecture.md`, `docs/design/<topic>.md`, or the repo's equivalent.
- **SKILL** — the *enforced rules*. Short, durable: "don't violate these laws." High bar: prefer extending or pointing at an existing skill. Write a new one only when an agent's default behavior would be wrong without it, and the rules are durable enough that future agents need to start off doing the right thing.
- **Plan** — the *execution sequence*. Time-bound: "to get from here to there, do these steps in this order." Usually lives in the app's plan mode for in-session work, or `planning-multi-agent-projects` for durable repo-tracked planning hubs.

A mature subsystem often has the ADR, design doc, and plan; a SKILL only when there's a recurring failure mode worth pinning. They cross-link.

## When to use

Write a design doc when:

- Building a new subsystem from scratch that contributors will need to navigate.
- Reshaping an existing subsystem significantly enough that the old mental model no longer applies.
- A decision (ADR) commits to a direction that needs more than a few paragraphs to explain.
- Onboarding pain is a recurring complaint for an area — the doc replaces tribal knowledge.
- A subsystem has invariants or contracts (complexity bounds, layering rules, ordering guarantees) that need a single canonical reference.

Don't write one for:

- Small features whose mechanism is obvious from the code.
- Decisions that fit in an ADR (no separate doc needed).
- One-off PR-level changes that don't outlive the PR.
- Execution plans — those go in a plan doc, not a design doc.
- Things better expressed as code comments or doc comments on the type.

## Rules

### 1. Discover the repo's convention first

Locations vary by repo:

- A flat `docs/design/<topic>.md` directory of focused subsystem docs.
- `docs/<topic>-architecture.md` at the repo root, paired with `docs/<topic>-plan.md`.
- A nested `docs/<area>/<topic>.md` layout.

Look at sibling docs before picking a location. **Match the established pattern** — don't introduce a parallel convention.

If the repo has no design-doc convention at all, default to `docs/design/<topic>.md` and mention the choice in your next message so the user can correct it.

### 2. Drafts live in the repo, on the branch

Don't stash design docs in a session scratch directory, `/tmp`, or any other location the user can't see in the file tree — a doc the user can't read is a doc they can't iterate on. A doc on a feature branch is, by definition, a draft; the branch and PR are what mark it as in-progress. Land the file at its real path from the first version and edit it in place.

### 3. Lead with orientation

Open the doc with a short "read this first" block: companion docs (ADR, SKILL, related design docs, active plans), and a one-paragraph summary of what the doc covers. Future readers should know within 30 seconds whether they're in the right place.

```markdown
# <Topic> — Architecture

> **Read this first.** Companion docs:
> - [`docs/adr/NNNN-<topic>.md`](...) — the decision that led here.
> - [`skills/<topic>/SKILL.md`](...) — the hard rules contributors must follow.
> - [`docs/<topic>-plan.md`](...) — execution sequence (history; not the design).

One paragraph: what this doc explains, and what it does **not** cover.
```

### 4. Explain the *why* before the *what*

The first substantive section should answer "why does this exist?" — what forced the current shape. Without that frame, the rest of the doc reads as arbitrary structure. Reference the ADR if there is one, but restate the framing in the design doc's own voice.

### 5. State the contract

If the subsystem has invariants — complexity bounds, layering rules, ordering guarantees, performance budgets, security properties — name them explicitly. A contract turns the doc from prose into something reviewers can hold a PR against.

If the contract has hard laws that contributors must apply during day-to-day work, those belong in a SKILL, not duplicated in the design doc. Link out, don't repeat.

### 6. Walk the mechanism

After the why and the contract, walk the actual mechanism: pipeline stages, data flow, key types, interaction sequences. Use ASCII or mermaid diagrams when they earn their place. Be concrete — name actual files, functions, and types.

Avoid generic boilerplate ("the request enters the system, is validated, and routed"). If the same sentence could appear in any design doc, delete it.

### 7. Name what's *not* settled

Design docs that pretend everything is figured out age badly. Include a section for:

- Known limitations and where they bite.
- Aspirational behavior that isn't yet implemented (mark clearly).
- Open questions and follow-up work.

This is what makes the doc honest. A reader can trust the rest if they see the unknowns named.

### 8. Pair with the other artifacts

Once written, cross-link:

- The ADR's `Related:` line points at the design doc.
- The SKILL (if any) cites the design doc as its long form.
- Active plans reference the design doc as their target shape.

Bidirectional links keep the four artifacts navigable.

### 9. Keep design docs and plans separate

A design doc says **what the system is**. A plan says **how we get there from here**. Plans are time-bound and become history once executed; design docs are durable references.

If a plan accumulates design content during execution, harvest the design into a real design doc and leave the plan as a record of the work. Don't let the plan doc become the de facto design doc — it ages out the moment the work ships.

### 10. Maintain or supersede; don't silently rewrite

When the system changes:

- **Small drift** — amend in place with a dated note ("Updated YYYY-MM-DD: <change>"), so readers know the doc has been touched recently.
- **Material reshape** — write a new design doc and link the old one as superseded. The historical doc still has value for context.
- **No longer relevant** — mark the doc as deprecated at the top; don't delete unless it's misleading.

## Common mistakes

- **Writing a design doc when an ADR would suffice.** If you can say the whole thing in Context / Decision / Consequences, write an ADR.
- **Writing a spec when you meant a design doc.** Specs describe external behavior; design docs describe internal mechanism. Don't conflate them.
- **Duplicating the SKILL's rules in the design doc.** The SKILL is the short form contributors load; the design doc is the frame. Cross-link, don't repeat.
- **Letting the plan become the design doc.** Plans are execution history. Harvest the design out before the plan rots.
- **Inventing structure for the sake of structure.** Design docs don't have a fixed template — match the shape of the system. A pipeline doc reads like a pipeline; a data-model doc reads like a data model.
- **Hand-waving the contract.** "It should be fast" is not a contract; "no hot path's cost depends on N" is.
- **Burying the why.** If the first section is "the API exposes endpoints X, Y, Z," readers don't know why they're here. Lead with the forces, not the surface.
- **Pretending the doc is complete.** Name the unsettled bits explicitly; readers will trust the doc more, not less.
- **Hard-wrapping the markdown.** Let lines flow naturally; renderers handle wrapping.

## Pressure-test

The temptation this skill prevents: reaching for a design doc whenever a system feels "important enough" to deserve one, when an ADR, a few code comments, or a README update would actually serve readers better. The excuse: "future contributors will want this written down." The loophole closer: a design doc earns its existence only when there's a *recurring* need for the explanation — onboarding pain, repeated misunderstandings, invariants reviewers can't enforce without it. If you cannot name the recurring need, write the ADR or the code comment and stop.

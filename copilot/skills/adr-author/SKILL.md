---
name: adr-author
description: Use when proposing or recording a significant technical decision (architecture change, new dependency pattern, public API change, hard-to-reverse choice) that should land as an Architecture Decision Record.
---

# Authoring ADRs

ADRs capture the framing behind significant technical choices. Repo-local conventions always win over the defaults here.

## When to use

The bar is high — single digits per year for mature projects. Default to **not** writing one.

Write an ADR for:

- Architecture, layering, or core data-flow changes that reshape how contributors think about the system.
- Major new dependencies, runtime patterns, or library categories the project will live with for years.
- Public API or persisted schema changes that are hard to migrate away from.
- Choices genuinely costly to reverse (storage format, auth model, deploy topology).
- Amending, superseding, or revisiting a prior ADR.

Skip for: routine refactors, bugfixes, dependency bumps, subsystem-internal design choices (write a design doc — see `design-doc-author`), or choices likely revisited within months.

Calibration: if you can't name a similar-stakes decision the repo has already recorded as an ADR, you're over-reaching. Propose it, get explicit agreement, then write it.

## Rules

### 1. Discover the repo's convention

Look for `docs/adr/`, `docs/decisions/`, `adr/`, or `architecture/decisions/`. Read the ADR README if present. **Never invent a new filename pattern in an established directory** — match sequential numbering (`0007-foo.md`) or date prefixes (`2026-05-16-foo.md`). If the repo maintains an index table, status convention, or any other ADR-adjacent ritual, follow it. New directory: default to `docs/adr/` with `YYYY-MM-DD-kebab-name.md` and confirm with the user.

### 2. Standard header

```markdown
# ADR NNNN: Title

- Status: Proposed | Accepted | Deprecated | Superseded by [NNNN](NNNN-....md)
- Deciders: (optional) @handles or team names
- Related: (optional) links to related ADRs, skills, or docs

## Context

## Decision

## Consequences

## Alternatives
```

Status: **Proposed** (under discussion), **Accepted** (in effect), **Deprecated** (no longer applies), **Superseded by [NNNN](...)** (link both directions).

### 3. ADR PR before implementation

Open the ADR as a separate PR in **Proposed** status; review before the implementation PR merges. Mid-implementation realization: stop, open the ADR PR, link them.

### 4. Context

Name the forces (performance, security, team capacity), the system constraints, and what the current approach fails at. A reader should understand why *now*. No hand-waving.

### 5. Consequences

Name what gets harder, what locks in, what follow-up this implies. Only-positive consequences = red flag.

### 6. Alternatives

One sub-heading per serious alternative. State what it would look like and concretely why it lost — "slower" is hand-waving; specific cost is not.

- **Empty section** means the decision wasn't real. Find genuine alternatives or skip the ADR.
- **Straw alternatives** ("do nothing", "rewrite it in COBOL") don't count.

### 7. Pair with a skill or design doc when needed

- ADR = decision/frame.
- Skill = day-to-day rules contributors load (`skills/<topic>/SKILL.md`).
- Design doc = subsystem shape (see `design-doc-author`).

Cross-link. Pair only when the rules need enforcing or the shape needs explaining beyond the ADR.

### 8. Amendments and supersession

- Minor: amend in place with a dated note.
- Material: new ADR; mark the old `Superseded by [NNNN](...)`; cross-link both ways.
- Never silently rewrite an Accepted ADR.

## Common mistakes

- Inventing a filename pattern in an established directory.
- Writing the ADR after the code merges.
- Skipping or strawing the Alternatives.
- Burying the decision in the implementation PR.
- Embedding the ADR in a planning doc instead of `docs/adr/`.
- Only-positive consequences.
- Promoting to Accepted without team review.
- Silently rewriting a Superseded ADR.

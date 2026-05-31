---
name: verify-before-claiming
description: Use when about to claim work is complete, fixed, passing, installed, synced, or ready for review.
---

# Verifying Before Claiming

Evidence before assertions.

## Gate

Before saying work is complete, fixed, passing, installed, synced, or ready:

1. Identify the command or check that proves the claim.
2. Run it fresh.
3. Read the output and exit status.
4. If it fails, report the actual state.
5. If it passes, make the claim with the relevant evidence.

## Common proof

| Claim | Proof |
|---|---|
| Tests pass | Test command exits 0 with no failures |
| Lint passes | Lint command exits 0 |
| Build succeeds | Build command exits 0 |
| Bug fixed | Original reproduction no longer fails |
| Skill installed | Sync/install command succeeds and target link/file exists |
| Requirements met | Checklist maps each requirement to code/docs/verification |

Do not rely on "should", prior runs, or another agent's success report.

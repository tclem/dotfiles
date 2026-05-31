---
name: pr-review-reply
description: Use when receiving PR review comments, code review feedback, suggested changes, or reviewer concerns that may require code or response changes.
---

# Handling Review Feedback

Treat review as technical input, not a command queue.

## Process

1. Read every comment and the surrounding diff/code.
2. Classify each item:
   - real issue to fix;
   - valid concern but different fix;
   - unclear, needs clarification;
   - not applicable or reviewer is wrong.
3. Fix real issues with the smallest coherent change.
4. Verify the affected behavior.
5. Reply to each thread when working on GitHub review comments, including when leaving something unchanged.

## Guidelines

- Do not blindly implement questionable feedback.
- Push back with evidence when the suggestion is wrong.
- If feedback is ambiguous, state your interpretation and ask before making risky changes.
- Follow the GitHub Posting Protocol before posting any GitHub reply.


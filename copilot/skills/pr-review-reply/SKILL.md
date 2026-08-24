---
name: pr-review-reply
description: Use when receiving PR review comments, code review feedback, suggested changes, or reviewer concerns that may require code or response changes.
---

# Handling Review Feedback

Treat review as technical input, not a command queue.

## Process

1. Enumerate every comment using the sources below, then read the surrounding diff/code.
2. Classify each item:
   - real issue to fix;
   - valid concern but different fix;
   - unclear, needs clarification;
   - not applicable or reviewer is wrong.
3. Fix real issues with the smallest coherent change.
4. Verify the affected behavior.
5. Reply to each thread when working on GitHub review comments, including when leaving something unchanged.

## Enumerating Copilot review comments

Read all three sources before concluding there are no comments:

- GraphQL `reviewThreads` for threads and `isResolved`.
- REST `pulls/<n>/comments` for inline comments.
- Every Copilot review `body` for `### Suppressed comments (N)`. Suppressed comments create no thread and appear in no inline list; the body is their sole source.

Enumerate Copilot reviews and their suppressed counts:

```shell
gh api repos/<owner>/<repo>/pulls/<n>/reviews \
  --jq '.[]|select(.user.login|test("copilot";"i"))|"\(.submitted_at) \(.state) @\(.commit_id[0:7]) suppressed=\(.body|capture("Suppressed comments \\((?<c>[0-9]+)\\)")?.c // "0")"'
```

Print any body with a nonzero count and read the suppressed section for its file, line, and prose. There is no thread to reply to, but its substance still requires triage.

Pitfalls:

- Review author `copilot-pull-request-reviewer` and inline-comment author `Copilot` are different identities. Filter case-insensitively; filtering inline comments by the review author's login returns a misleading zero.
- `Comments generated: N` counts only new visible comments. It matches the inline count whether or not comments were suppressed; only the suppressed-comments section distinguishes the cases.
- Threaded replies create empty `COMMENTED` reviews under your handle. Filter to the bot and compare `submitted_at` with the last re-request instead of counting reviews.

A check whose failure is indistinguishable from a negative result cannot establish that there are no comments.

## Guidelines

- Do not blindly implement questionable feedback.
- Push back with evidence when the suggestion is wrong.
- If feedback is ambiguous, state your interpretation and ask before making risky changes.
- Use app-native tools for replies, resolution, and re-requests when available.
- Follow the GitHub Posting Protocol before posting any GitHub reply.

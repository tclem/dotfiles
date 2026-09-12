---
name: pr-review-reply
description: Use when receiving PR review comments, code review feedback, suggested changes, or reviewer concerns that may require code or response changes.
---

# Handling Review Feedback

Treat every review item as a hypothesis to adjudicate, neither a command nor a nuisance. Skepticism applies equally to accepting and dismissing feedback.

## Process

1. Read every comment and the surrounding diff/code.
2. Classify each item:
   - **accepted** — the finding and proposed direction are correct;
   - **accepted with different fix** — the concern is real, but the proposed fix is incomplete or wrong;
   - **unclear/open** — the evidence or intended invariant is unresolved;
   - **dismissed with proof** — the finding does not apply and the evidence meets the dismissal burden below.
3. Establish the exact invariant the review item is testing. A question can expose a broader issue even when its suggested fix is wrong.
4. Gather evidence before changing code or replying.
5. Fix accepted items with the smallest coherent change and verify the affected behavior.
6. Reply to every GitHub review thread. Resolve only after the evidence supports the stated outcome.

## Dismissal burden

Classifying feedback as wrong or not applicable requires evidence at least as strong as accepting it:

- State the exact invariant and why the finding would violate it.
- Search the complete affected universe, or explain how the universe is bounded.
- Use a reproduction, counterexample, or focused test when behavior can be exercised.
- List what was checked in the reply.

A plausible subsystem story, a code-reading rationale, or two sampled call sites is not proof. Do not turn "I can explain why the reviewer is wrong" into "the reviewer is wrong."

## Closed-world trigger

Feedback containing existential or cross-cutting language — **any other**, **all**, **none**, sibling implementations, parity, config, rollout, protocol, auth, or schema — requires a closed-world inventory before replying.

Build an explicit matrix of the relevant producers, consumers, sibling implementations, and environment variants. Record the invariant and status for each row. A negative conclusion must name the universe and list every item checked; sampling cannot prove absence.

## Second-reader gate

Before dismissing high-impact, cross-cutting, or ambiguous feedback, ask a different frontier reviewer or subagent to independently try to prove the reviewer right. Give it the original comment, invariant, affected-universe inventory, and evidence; do not ask it to confirm the first conclusion.

If independent verification is unavailable or disagreement remains, classify the item as **unclear/open**, leave the thread unresolved, and ask tclem with the current evidence. Never post or resolve a dismissal as certainty.

## Reply discipline

- Do not blindly implement questionable feedback, but do not push back until the dismissal burden is met.
- Say which outcome applies and cite the evidence that supports it.
- For **accepted with different fix**, acknowledge the broader concern before explaining the different implementation.
- For **unclear/open**, state the uncertainty and keep the thread open.
- Follow the GitHub Posting Protocol before posting any reply.

## Common mistakes

- Treating a question as only a proposed patch instead of testing the broader invariant it points at.
- Explaining one subsystem without inventorying its siblings.
- Using sampled checks to make an absence claim.
- Asking a verifier to agree rather than to falsify the dismissal.
- Resolving a thread because a reply sounds confident rather than because the evidence is complete.

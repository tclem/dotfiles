---
name: pr-review-reply
description: Use when receiving PR review comments, code review feedback, suggested changes, or reviewer concerns that may require code or response changes.
---

# Handling Review Feedback

Treat every review item as a hypothesis to adjudicate, neither a command nor a nuisance. Skepticism applies equally to accepting and dismissing feedback.

## Process

1. Read every comment and the surrounding diff/code.
2. State the exact invariant or question the review item is testing. A question can expose a broader issue even when its suggested fix is wrong.
3. Gather evidence that applies to the claim: a reproduction, failing test, direct code-path trace, authoritative contract, or equivalent.
4. Classify each item:
   - **accepted** — the finding and proposed direction are correct;
   - **accepted with different fix** — the concern is real, but the proposed fix is incomplete or wrong;
   - **unclear/open** — the evidence or intended invariant is unresolved;
   - **dismissed with proof** — the finding does not apply and the evidence meets the burden below.
5. Fix accepted items with the smallest coherent change and verify the affected behavior.
6. Reply to every GitHub review thread. Resolve only after the evidence supports the stated outcome.

## Evidence burden

Acceptance and dismissal require evidence appropriate to the claim. Do not force a reproduction when a contract or direct code-path trace is the authoritative evidence.

For acceptance, show the failing behavior, violated contract, or traced path that makes the concern real. For dismissal, the burden is at least as strong:

- Explain why the evidence satisfies the invariant rather than merely offering a rationale.
- Search the complete affected universe, or explain how the universe is bounded.
- Use a counterexample or focused test when behavior can be exercised.
- List what was checked in the reply.

A plausible subsystem story, a code-reading rationale, or two sampled call sites is not proof. Do not turn "I can explain why the reviewer is wrong" into "the reviewer is wrong."

## Closed-world trigger

A closed-world inventory is required whenever either the reviewer finding or the proposed response claims completeness, absence, exclusivity, parity, or coverage over a set. This includes claims such as **any other**, **all**, **every**, **none**, **no other**, **only**, or **exhaustive**; trigger on the claim, not the keyword.

Config, rollout, protocol, auth, and schema are high-risk domains when the claim spans producers, consumers, sibling implementations, environments, or variants. Merely mentioning one of those domains in a narrow comment does not trigger a matrix.

Once triggered, bound the affected universe and build an explicit inventory or matrix of its relevant members. Record the invariant and status for each row. A negative conclusion must name the universe and list every item checked; sampling cannot prove absence.

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
- Triggering closed-world work from a domain keyword rather than a set-wide claim.
- Asking a verifier to agree rather than to falsify the dismissal.
- Resolving a thread because a reply sounds confident rather than because the evidence is complete.

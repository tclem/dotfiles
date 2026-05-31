---
name: replying-to-peer-sessions
description: 'Use when sending any cross-session message after kickoff (send_session_message, send_chat_message), or deciding whether to send one at all.'
---

# Replying to Peer Sessions

After kickoff, the other agent has state. Replies should be terse, ask-first, and free of process narration. Kickoff prompts are context-rich on purpose; replies are not.

This skill is user-level only and should not be mirrored into a repo.

## When to use

- Composing any `send_session_message` or `send_chat_message` that is **not** the kickoff.
- Replying to a `<cross_session_message>` from a peer agent.
- Forwarding a user instruction to a session that already has the goal.

Do not use for:

- Initial kickoff prompts (those should be context-rich; use `delegating-plan-work` or write directly).
- Messages to the user in chat (those have separate guidance).
- GitHub posts (PR comments, issue replies — see `pr-authoring`, `handling-review-feedback`).

## Stay engaged or detach?

Before sending any reply, decide which relationship the two sessions are in. The wrong choice wastes both contexts.

- **Parent managing child work.** The originating session delegated a scoped task and is tracking it. Status updates, blockers, and "done — here's the artifact" replies belong on the wire. The parent uses them to decide what's next.
- **Peers collaborating on related work.** Two sessions exploring the same system, sharing findings, or coordinating overlapping edits. Keep the channel open; replies should carry information the other side cannot get itself.
- **Detached work.** A session spun up to fix an unrelated bug, draft a side PR, or chase a tangent. Once kickoff lands, there is no ongoing relationship. Do not narrate progress, do not announce completion, do not loop the originator in. The notification of session creation is the last message that should flow. Replying back just pollutes the other agent's context with work they no longer care about.

If you're unsure which bucket applies, ask: would the recipient agent change what they do next based on this message? If no, do not send it.

## Rules

1. **Lead with the ask, the answer, or the correction.** First sentence is the operational thing. No preamble. No "Great find", "Acknowledged", "Excellent reframing", "Thanks for the update".

2. **Do not restate what they sent you.** If they reported X, do not open with "You found X." They know.

3. **No state narration — yours or theirs.** Cut "I just made the same mistake", "wanted to make sure", "process reminder for both of us", "apologies for prior turns", "you may have missed this", "wanted to make sure this didn't get lost behind X", "they don't care about Y". You do not know what the agent has in context, and they do not need yours. Either correct the work or do not.

4. **One ask per message when possible.** Multiple asks: terse numbered list, no section headers, no framing paragraphs.

5. **No GitHub Posting Protocol signature.** Cross-session messages are not GitHub posts. Do not append the signature block.

6. **No section headers (`##`) inside reply messages.** A reply with two paragraphs and a bullet list does not need headers. Headers add scannability that the recipient does not need for a single-message exchange.

7. **No re-issuing the same ask in new wording.** If the agent acknowledged a request but the user re-prompts you to send it, do not re-narrate — say "re-sending in case it slipped" once, list the asks, stop. If they already addressed it (cross-notification), reply "acknowledged" or nothing.

8. **Match the agent's register.** Peer agents are operating under similar autopilot constraints. Treat them as a peer engineer on Slack, not as an audience needing context.

## What a good reply looks like

Good (correction):

> Cannot skip Spokes — Go does not skip it either (`search.go:189-196`, unconditional `blobFilter.Apply`). The real divergence is doc-list sizing: Go clamps to `RequestedDocs` (~30) before calling Spokes; Rust passes the full `docs_to_return` list (~100-400). Fix is to clamp before the Spokes call, matching Go's ordering.

Good (nit list):

> Three nits on #15146, none blocking:
>
> 1. Inconsistent tag key — `resolve_nwos` uses `CLUSTER_TAG`, others use `"cluster"`.
> 2. PR body claims percentiles enabled but no config diff — confirm UI vs missed.
> 3. `fetch_repo_metadata_opt` times empty-doc calls — short-circuit before the timer.

Good (acknowledgment of completion):

> Acknowledged.

Bad (the same nit list, bloated):

> Re-sending — wanted to make sure these didn't get lost behind the Spokes thread. Three small nits on PR #15146, none blocking, easy follow-up commit on the same branch:
>
> 1. **Inconsistent tag key.** `resolve_nwos` uses `CLUSTER_TAG => …`, the other two new metrics use `"cluster" => …`. Probably the same string at runtime but worth unifying for grep-ability [...]
>
> [...]
>
> Spokes timer bracketing (RPC only, stops before `documents.retain_mut`) is correct — leave that alone.

The bad version doubles the word count to convey the same information. Every "wanted to make sure", every parenthetical, every header is friction the recipient pays.

## Common mistakes

- **Treating each reply as a fresh kickoff.** The agent has state. Stop restaging.
- **Using replies for meta-coaching.** "Let's both be rigorous from here" is for your own internal notes, not the wire.
- **Apologizing to a peer agent.** They do not need the apology and it dilutes the correction.
- **Wrapping a 3-item list in 4 paragraphs of framing.** If the list is the message, send the list.
- **Editorializing on the user's framing.** When the user says "send the nits", send the nits. Do not explain why you are sending them now.
- **Appending the GitHub Posting Protocol signature.** It does not apply to cross-session messages.
- **Messaging a detached session out of politeness.** "Just letting you know I finished the unrelated bug fix" is noise. If the originator did not need the result to make a decision, do not send the update.

## Pressure-test

Two temptations this skill prevents. First, adding "polish", "warmth", or "context" to every reply because it feels rude or curt to send three bullets with no preamble. Second, sending updates to a detached session because it feels rude to go quiet after they spun you up. The excuses: "this case has nuance the agent needs" and "they'd want to know". The loophole closer: if the message changes what the recipient does next, send it; if it does not, cut it. Politeness is not a reason to send.

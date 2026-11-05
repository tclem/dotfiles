# Evaluation

Pinned `eval-skill` v1 at `tclem/agent-retro@149fc4430c5066b002442f704b2a124eb1f12a0c`; behavior and discovery modes; `gpt-5.6-sol`, low effort, two trials per case, two fixed distractors.

The v1 harness accepts only `review_feedback_v1`, so these synthetic cases evaluate review decisions about Datadog CLI selection, auth, and mutation safety. They do not measure CLI task execution, live Datadog access, or full feature parity.

Cases: target `pup-change-stories-is-supported`; sentinels `pup-auth-status-avoids-keychain`, `pup-auth-refresh-is-not-automatic`, `pup-events-aggregate-gap`, and `pup-logs-flex-fallback-limits-claim`. These cover operations observed in the 30-day usage audit; the facts pin Pup 2.4.1 command help and contain no account data or credentials.

| Variant | SHA-256 | Chars | Targets | Sentinel | Discovery | Decision |
|---|---|---:|---:|---:|---:|---|
| baseline (`upstream-pup-241`) | `7ac927770667adab61fd407d39167210b3ae963cde44c5c8111e7a820589579f` | 8,921 | 0/2 | 7/8 | 0/10 success; 0/10 discovered, 6/10 invoked | reference |
| candidate (`dotfiles`) | `d9b3b9b902c92bd1d1f9b4b63c2a3d7b9a183e068306416a31708ff3aca8f986` | 3,048 | 2/2 | 8/8 | 0/10 success; 1/10 discovered, 8/10 invoked | selected |

Final run `d887b5db-f721-43ef-88e4-b819aaf0489d`: pinned `eval-skill` v1, behavior and discovery modes, `gpt-5.6-sol` at low effort for author and judge, two trials per case, two fixed distractors, seed `17795688054449247468`. The target passed 2/2 versus 0/2 baseline, every candidate sentinel and hard assertion passed, and discovery did not regress: skill invocation rose from 6/10 to 8/10 and discovery from 0/10 to 1/10. The candidate was selected. A preceding run exposed a 1/10 discovery regression; narrowing the skill description to include safe authentication checks resolved it. This synthetic evaluation does not establish full Pup/MCP parity or live account coverage.

Earlier bounded live read-only checks returned one metrics series and zero indexed log records. In a fresh check after the evaluation, the metrics query failed with expired authentication. The logs query automatically refreshed the access token, then returned zero indexed records; Flex storage remained unavailable, so that result may not cover the requested range. No Datadog data was written, but Pup did refresh credentials automatically. The MCP must remain enabled because live metrics access is currently unverified, Pup 2.4.1 does not provide the observed `aggregate_events` operation, and broader parity remains unverified.

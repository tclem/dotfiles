# Evaluation

Pinned `eval-skill` v1 at `tclem/agent-retro@149fc4430c5066b002442f704b2a124eb1f12a0c`; behavior and discovery modes; `gpt-5.6-sol`, low effort, two trials per case, two fixed distractors.

The v1 harness accepts only `review_feedback_v1`, so these synthetic cases evaluate review decisions about Datadog CLI selection, auth, and mutation safety. They do not measure CLI task execution, live Datadog access, or full feature parity.

Cases: target `pup-auth-refresh-is-not-automatic`; sentinels `pup-auth-status-avoids-keychain`, `pup-events-aggregate-gap`, and `pup-logs-flex-fallback-limits-claim`. The facts pin Pup 2.4.1 command help and source behavior; they contain no account data or credentials.

| Variant | SHA-256 | Chars | Targets | Sentinel | Discovery | Decision |
|---|---|---:|---:|---:|---:|---|
| baseline | `7ac927770667adab61fd407d39167210b3ae963cde44c5c8111e7a820589579f` | 8,921 | 2/2 | 6/6 | 0/8 success; 1/8 discovered, 3/8 invoked | reference |
| candidate | `e16a602d0546c62a8ce9c67968166f472e28a46e7120bda4446a85545938fbf1` | 2,629 | 2/2 | 6/6 | 1/8 success; 1/8 discovered, 6/8 invoked | reject: target gain 0.00 |

Final run `94b014e0-185e-4ea7-8c31-a72be43f7a89`: all hard assertions passed in behavior mode, with no sentinel regression. The auth-refresh target passed 2/2 for both variants, below the required 0.20 improvement. Discovery success improved from 0/8 to 1/8; direct skill invocation increased from 3/8 to 6/8. The candidate was not selected and is marked disabled in this branch to prevent activation. The hash above is the evaluated enabled candidate; the final file adds only the `disabled: true` promotion gate.

Earlier diagnostics exposed two assertion problems, which were corrected before this run: an exact proposed-change count rejected valid multi-part answers, and requiring the literal word "incomplete" rejected correct wording. The final cases avoid those constraints.

Bounded live read-only checks succeeded: `pup metrics query --query 'avg:system.cpu.user{*}' --from 5m --to now --read-only` returned one series; `pup logs search --query 'status:error' --from 5m --to now --limit 1 --read-only` returned zero indexed records. Pup warned that Flex storage was unavailable and retried against indexed logs, so that empty result does not cover Flex data. No Datadog writes or credential changes were made. The MCP must remain enabled because Pup 2.4.1 does not provide the observed `aggregate_events` operation, and broader parity remains unverified.

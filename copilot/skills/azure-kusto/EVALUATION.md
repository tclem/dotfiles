# Evaluation

Evaluated against pinned [`eval-skill` v1](https://github.com/tclem/agent-retro/blob/149fc4430c5066b002442f704b2a124eb1f12a0c/docs/skill-eval-v1.md), using behavior and discovery modes, `gpt-5.6-sol` author and judge at low effort, two trials per case, seed `20261105`, and two fixed distractors.

Cases: targets `kusto-management-endpoint`, `kusto-no-auth-prompt`, and `kusto-partial-query-error`; sentinel `kusto-complete-request-sentinel`. The harness only supports structured `review_feedback` cases, so these synthetic code-review scenarios are a proxy for Kusto REST guidance, not an evaluation of live query execution or Azure CLI workflows.

| Variant | SHA-256 | Chars | Targets | Sentinel | Behavior hard assertions | Rubric | Discovery success (discovered, invoked) | Decision |
|---|---|---:|---:|---:|---:|---:|---:|---|
| baseline | `d91ccea9b2c5afb00a322fd871b6c39cde207a0568cda96814c73b5694201d33` | 92 | 5/6 | 2/2 | 7/8 | 7/8 | 1/8 (3/8, 4/8) | reject |
| full | `9bd5b61d81130366ed95c9fbaf048799c8bb7e1d0a8b6a76d40e52c551d8c4e1` | 2,449 | 3/6 | 2/2 | 8/8 | 5/8 | 1/8 (1/8, 8/8) | reject |
| compressed | `81a937c25ac90200cb61e064c7946a2297dfaef1c6643c562d5b3e5b42eddb0a` | 1,469 | 2/6 | 2/2 | 7/8 | 5/8 | 2/8 (3/8, 6/8) | reject |

No candidate was selected. The full skill's target success was 0.50 versus the baseline's 0.83, below the required 0.20 improvement; its discovery success matched baseline. The compressed variant scored lower on target success and missed one hard assertion. Growth was allowed only with the smaller variant, but it did not earn promotion. The candidate is disabled pending a passing evaluation.

After the failed promotion gate, the source was marked disabled. Its current SHA-256 is `622686afc543c401750121d668a3358b6ec583aeb7504b7d1591417d68317c4a`; the `full` hash in the table is the exact enabled variant evaluated before that metadata change.

An earlier diagnostic run used two invalid assertions: one rejected a correct explanation for why `az login` must not run, and another paired facts describing a missing response check with a reviewer comment to remove that check. The cases were corrected before this final run; the failed promotion result above uses the corrected cases.

The pinned harness checkout needed a local compatibility patch removing obsolete `--no-remote` and `--no-remote-export` CLI flags; no evaluator or case files are part of this repository change. Representative bounded read-only KQL and metadata requests were separately verified through Azure CLI REST using the existing login, without starting authentication. The skill covers the observed inventory, Redis, and documentation paths at a high level, but it does not replace the broad Azure MCP's other service-specific tools.

## Description recheck

Pinned `eval-skill` v1 at the same commit; behavior and discovery modes; `gpt-5.6-sol` author and blind judge, low effort, two trials per case, seed `20261105`, and the same two fixed distractors.

Cases: targets `kusto-auth-audience`, `kusto-management-severity`, `kusto-management-endpoint`, `kusto-no-auth-prompt`, and `kusto-partial-query-error`; sentinel `kusto-complete-request-sentinel`. The candidate used the focused Azure CLI/Kusto REST trigger shown in its frontmatter. The compressed alternative used the same trigger.

| Variant | SHA-256 | Chars | Targets | Sentinel | Hard assertions | Rubric | Discovery success | Decision |
|---|---|---:|---:|---:|---:|---:|---:|---|
| baseline | `d91ccea9b2c5afb00a322fd871b6c39cde207a0568cda96814c73b5694201d33` | 92 | 8/10 | 2/2 | 10/12 | 12/12 | 2/12 | reject |
| full | `5af13b837c8afd1ae3d4e8f05f94235e9acd357271d7f8203b3a1c8a962d8764` | 2,643 | 8/10 | 2/2 | 12/12 | 10/12 | 1/12 | reject |
| compressed | `cab04eddfe415470b71400ac80d877faf233b0446709bd86e38698c5307c593f` | 1,586 | 7/10 | 2/2 | 12/12 | 9/12 | 0/12 | reject |

No candidate was selected. The full candidate matched baseline target success (0.80), below the required 0.20 improvement, and discovery success regressed from 0.167 to 0.083. The compressed variant performed worse on targets and discovery. Keep the candidate disabled; neither the evaluation nor this iteration authorizes activation or Azure MCP removal.

The harness again required the local compatibility patch described above. These structured review-feedback cases are synthetic proxies; they do not evaluate live Kusto execution or Azure CLI workflows.

## Review-scope promotion run

Pinned `eval-skill` v1 at `149fc4430c5066b002442f704b2a124eb1f12a0c`; behavior and discovery modes; `gpt-5.6-sol` author and blind judge at low effort; two trials per case; seed `20261105`; two fixed distractors. Run `e3308708-5b52-41a9-8467-6f25f4d1fbe2`.

The target cases are `kusto-management-endpoint` and `kusto-partial-query-error`; sentinels are `kusto-auth-audience`, `kusto-complete-request-sentinel`, `kusto-management-severity-contract`, and `kusto-no-auth-prompt`. The endpoint target now asserts exactly one proposed change, because an endpoint fix does not independently require response parsing or test edits.

| Variant | SHA-256 | Chars | Targets | Sentinels | Hard assertions | Rubric | Discovery success (discovered, invoked) | Decision |
|---|---|---:|---:|---:|---:|---:|---:|---|
| baseline | `d91ccea9b2c5afb00a322fd871b6c39cde207a0568cda96814c73b5694201d33` | 92 | 1/4 | 8/8 | 9/12 | 9/12 | 6/12 (8/12, 8/12) | reject |
| full | `9e0888f76842a98399ce1f70510025edfb5a27d53ca0baafa1950308acb8e702` | 2,709 | 3/4 | 8/8 | 12/12 | 11/12 | 11/12 (12/12, 12/12) | reject; equivalent smaller variant |
| compressed | `4bacc0c7c6ed8ac55859a27e55d4e8b1487ed17443e577a2ad37f4a5bcd146d2` | 1,705 | 3/4 | 8/8 | 12/12 | 11/12 | 9/12 (11/12, 11/12) | select |
| minimal | `0ae53b064d4494e1cd5be21f6123a53a02c3a0994154cb375b0af1bc7790c732` | 839 | 2/4 | 7/8 | 9/12 | 10/12 | 12/12 (12/12, 12/12) | reject; hard assertion and sentinel regression |

The compressed candidate improved target success from 0.25 to 0.75, passed every hard assertion, preserved all sentinel results, and improved discovery success from 0.50 to 0.75. Its smaller ablation was not equivalent: it failed a hard assertion and regressed a sentinel. The pinned gate selected the compressed candidate; the full version was rejected as equivalent to the smaller selected candidate. The selected candidate's exact evaluated content is committed with only `disabled: true` added afterward to keep activation separate from authoring.

The pinned evaluator checkout required local-only compatibility edits for the current CLI flags and skill-load telemetry; its telemetry parser tests and formatting check passed. The evaluator checkout and local edits are not part of this repository change. This synthetic review-feedback suite does not validate live query execution or cover all Azure MCP service-specific capabilities.

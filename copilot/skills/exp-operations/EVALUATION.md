# Evaluation

Pinned `eval-skill` v1 at `tclem/agent-retro@149fc4430c5066b002442f704b2a124eb1f12a0c`; behavior and discovery modes; `gpt-5.6-sol`, low effort, two trials per case, two fixed distractors.

Cases: targets `exp-rest-access-target`, `exp-scorecard-wait-target`, and `exp-teamship-repair-target`; sentinel `exp-approved-stop-sentinel`. Evidence is synthetic and contains no private transcripts, IDs, or assignment context.

| Variant | SHA-256 | Chars | Targets | Sentinel | Discovery | Decision |
|---|---|---:|---:|---:|---:|---|
| baseline | `98add7b4b9725a6955771f39107bf61bd789a8e23c4735691640875ed43f0b4b` | 184 | 2/6 | 2/2 | 5/8 | reject |
| full | `f402c6e945089bbde3348fafbedc0c5d751f513cee1d0df8327b19d78a8231dc` | 4,842 | 5/6 | 2/2 | 7/8 | reject |
| compressed | `6401032363094a3b7eb050845677f09bdbbd67470774a4235070df8cb6e0a72e` | 3,198 | 6/6 | 2/2 | 8/8 | select |
| ablated | `53e8dfaa3e355c4df6c885435c5ff299b9a1ccd0c4746f3ee0d01069c38ddad3` | 659 | 0/6 | 2/2 | 3/8 | reject |

The selected candidate passed all 8/8 behavior hard assertions and all 8/8 discovery/invocation trials, improved aggregate targets from 0.33 to 1.00, and had no sentinel regression. The smaller ablation lost all target behavior.

Two diagnostics failed before the final gate: the first overconstrained review-classification wording; the second exposed a CLI event compatibility gap. The pinned evaluator was locally compatibility-patched and tested to accept successful skill-tool telemetry whose source is explicitly `project`, equivalent to its legacy `session.skills_loaded` check. No promotion decision used either failed diagnostic.

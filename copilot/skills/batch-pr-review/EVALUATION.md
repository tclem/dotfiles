# Evaluation

Pinned `eval-skill` v1 at `tclem/agent-retro@149fc4430c5066b002442f704b2a124eb1f12a0c`; behavior and discovery modes; `gpt-5.6-sol`, low effort, two trials per case, two fixed distractors.

Cases: targets `batch-research-before-fanout-target`, `batch-authority-and-models-target`, and `batch-live-reconciliation-target`; sentinel `batch-model-overuse-sentinel`. Evidence is synthetic and contains no private transcripts, repository details, or review content.

| Variant | SHA-256 | Chars | Targets | Sentinel | Discovery | Decision |
|---|---|---:|---:|---:|---:|---|
| baseline | `c733df0af505b77daef6034614858ccdabbb0a9922e6f8e6d1639328f875449a` | 161 | 2/6 | 2/2 | 2/8 | reject |
| selected | `122e69421ca01cefe9591336a27f141f76338f8bc80d0ca1f467757b0246ec2c` | 6,126 | 6/6 | 2/2 | 6/8 | select |
| ablated | `aaa3ecb1cd6f2f4a8e9ea7a11f22b873ad2ab850fdcaedfd3f906b8d84e6eb48` | 276 | 4/6 | 1/2 | 1/8 | reject |

The selected candidate passed all 8/8 behavior hard assertions, improved aggregate targets from 0.33 to 1.00, preserved the sentinel, and improved combined discovery from 0.25 to 0.75. The smaller ablation lost live-reconciliation behavior, regressed the sentinel, and regressed discovery.

Diagnostics exposed brittle prose-substring assertions before the final gate; the frozen cases now assert structured decision boundaries rather than exact wording. The pinned evaluator was locally compatibility-patched and tested to recognize successful project-skill telemetry emitted by Copilot CLI 1.0.94, equivalent to its legacy `session.skills_loaded` event.

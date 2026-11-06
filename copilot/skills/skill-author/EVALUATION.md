# Evaluation

Pinned `eval-skill` v1 at `tclem/agent-retro@149fc4430c5066b002442f704b2a124eb1f12a0c`; behavior mode; `gpt-5.6-sol` author and blind judge, low effort, two trials per case, seed `20261021`.

Cases: target `evaluation-evidence-placement-target`; sentinel `concise-pr-body-sentinel`. Evidence is synthetic and contains no private transcripts, repository details, or pull request content.

| Variant | SHA-256 | Chars | Target | Sentinel | Hard assertions | Decision |
|---|---|---:|---:|---:|---:|---|
| baseline | `08b0aff30780463d981e03884cb409f7e0fee61bdff91daa6bdbe451a9ee3dac` | 7,604 | 0/2 | 2/2 | 4/4 | reject |
| selected | `c86ebddef81e5ea90b3e3f7ceb1a503a322f64b19d4c11354d7f43c41ba497cc` | 7,729 | 2/2 | 2/2 | 4/4 | select |
| ablated | `3988bd7e299c6b2e2a2a3b2c2412c9e0368c1ea0526a5a3fe6b4641d89e39273` | 7,564 | 0/2 | 2/2 | 4/4 | reject |

The selected candidate improved the target from 0.00 to 1.00, preserved the sentinel, and passed the destination-authority rubric in both trials. The smaller full-skill ablation kept PR bodies as an allowed destination and lost both target trials.

Four diagnostic gates failed before the final selection: the first case leaked the desired destination through its evidence, prose/classification/change-count assertions overconstrained valid outputs, and the first ablation removed unrelated skill content. None contributed to the promotion decision.

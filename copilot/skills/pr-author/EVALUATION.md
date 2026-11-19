# Evaluation

Pinned `eval-skill` v1 at `tclem/agent-retro@149fc4430c5066b002442f704b2a124eb1f12a0c`, run with `gh agent-retro` 0.1.1; behavior mode; `gpt-5.6-sol` author and blind judge, low effort, two trials per case, seed `20261119`.

Cases: target `pr-body-key-decision-target`; sentinels `pr-body-obvious-fix-sentinel` and `pr-body-no-journey-sentinel`. Evidence is synthetic and contains no private transcripts, repository details, or pull request content.

| Variant | SHA-256 | Chars | Target | Sentinel | Hard assertions | Decision |
|---|---|---:|---:|---:|---:|---|
| baseline | `2bc3c79cbd4c6a6213d9d8928364c1851d7ce81d95b18b84f9801a02ba5c2006` | 7,920 | 0/2 | 3/4 | 6/6 | reject |
| selected | `8c4c324a0ea41d178fdb4e2a3420bc5dbea4e6a7319b3a196a39377f8f21ca09` | 7,896 | 1/2 | 4/4 | 6/6 | select |

The selected candidate lets a body carry the problem, the approach, and the one decision a reviewer would question, and still keeps an obvious fix to one sentence. Baseline bodies dropped either the approach or the reason the design held. The judge returned malformed output for the first target trial, which left both variants unscored there.

One diagnostic run before selection failed on case bugs: `Validation` matched inside "invalidation" and `##` normalized to an empty needle. That run also showed the first candidate padding the obvious fix with a sentence that restated the diff, which the selected wording fixes.

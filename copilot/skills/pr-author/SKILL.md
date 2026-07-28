---
name: pr-author
description: Use when creating a GitHub pull request, or when updating an existing PR's title or body so it matches what the code actually does.
user-invocable: true
---

# Authoring a Pull Request

Author or refresh a PR's title and body so they describe the final diff — same rules whether creating a new PR or rewriting one that drifted from the code.

Iterate on the live PR body, not on draft text in chat. Create it (draft if unsure) or update it, then refine in place — a real PR is easier to react to than loose text in a conversation. Don't stage the body for yes/no sign-off before posting.

## What the body is for

A PR body answers one question: **why does this diff exist?** The reviewer learns *what* changed from the code; the body supplies the *why* they can't — the bug, the constraint, the decision. Test every sentence against it: explains why → keep; otherwise cut. When the why is one sentence, the body is one sentence.

- **Never restate the diff, at any length.** Not a file-by-file recap, not one compressed sentence naming what was added. Being short doesn't redeem a sentence the reviewer can read straight off the diff.
- **Never narrate the dev journey.** No "tried X then Y", no "fixup after review", no changelog of iterations. State a decision as its current rationale ("uses Y because Z"), not as a fix-up story or a contrast with an earlier proposal — fix the stale doc instead of making the reader chase it.
- **Route nuance to where the reviewer meets it.** Only why the *whole* diff exists belongs in the body. Why one line reads as it does goes in a **code comment**; a point preempting a question about one hunk goes in a **PR review comment**. A body that feels thin needs more *why*, not more *what*.
- **Carry the causal chain with inline links.** Attach each link to its noun phrase so context rides along at zero length — the link replaces backstory, it doesn't add to it. Link to the thing's **canonical resource** (a flag to its flag page, a service to its catalog), not the PR that created it unless the PR *is* the canonical thing. Never a bare `#1234` or a trailing "Related PRs" line.
- **No process status.** No CI green/red, force-push notes, or self-review findings already fixed — the reviewer sees CI in GitHub.

## Decide: create or update

From the branch, run `gh pr view --json number,title,body,baseRefName 2>/dev/null`. If it returns a PR, this is an **update** — skip to [Update an existing PR](#update-an-existing-pr). Otherwise follow **Create**.

## Create

1. **Assess state.** `git rev-parse --abbrev-ref HEAD && git status --short && git remote get-url origin`. Extract owner/repo; get the default branch via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`. If on the default branch, create a feature branch first.
2. **Commit.** Group changes into logical, atomic commits — one is fine if the change is cohesive. Subject lines under 72 chars, specific.
3. **Push.** `git push -u origin HEAD`. Don't merge or rebase the base branch just because it moved; update from base only on conflicts, failing checks, branch protection, or explicit request.
4. **Use the template if one exists.** Check for it, and if found you **MUST** use its structure — fill every section, no placeholders. If unsure how to fill a section, ask rather than guess.

   ```bash
   for f in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md \
     docs/pull_request_template.md pull_request_template.md PULL_REQUEST_TEMPLATE.md \
     .github/PULL_REQUEST_TEMPLATE/*.md; do [ -f "$f" ] && echo "Found: $f"; done
   ```
5. **Detect chain-stacking.** When a project ships as a stack of dependent PRs, base PR k+1 on PR k's head branch, not the default branch, so the reviewer sees only what k+1 adds. Retarget to default only when PR k merges.

   ```bash
   default_branch=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
   if ! git merge-base --is-ancestor "origin/$default_branch" HEAD; then
     for ref in $(gh pr list --state open --json headRefName --jq '.[].headRefName'); do
       git merge-base --is-ancestor "origin/$ref" HEAD 2>/dev/null && echo "stacked on: $ref"
     done
   fi
   ```

   If stacked, surface it ("Stacked on `<branch>` (PR #N). Base on it or on `<default>`?"), default to the stacked base, and add a blockquote near the top of the body noting it's stacked on the prior PR and will be retargeted to the default branch when that merges. Pass `--base <stacked-branch>` to `gh pr create`; retarget after the upstream merges via [an API edit](#applying-edits).
6. **Draft.** Title: concise, following repo conventions (`feat:`, `fix:`). Body: apply the content test above. Reference an issue if context suggests one (`Fixes #123`). Don't add boilerplate "Non-goals"/"Follow-ups" sections — call a non-goal out only when its absence would mislead. Append the GitHub Posting Protocol signature; keep `Co-authored-by:` out of the body (commit messages only).
7. **Create** via [an API edit](#applying-edits): an app-native tool, or `gh pr create --title … --body-file … --base <default>`. Prefer a draft when uncertain. Display the PR URL.

## Update an existing PR

Use when an agent has iterated and the title/body no longer matches the code. Rewrite both to describe the current diff.

1. **Re-ground in the diff.** Never rewrite from memory or the old body.

   ```bash
   num=$(gh pr view --json number --jq .number)
   base=$(gh pr view --json baseRefName --jq .baseRefName)
   git fetch origin "$base"
   git diff --stat "origin/$base"...HEAD && git log --oneline "origin/$base"..HEAD
   git diff "origin/$base"...HEAD          # full diff; skim for surprises
   ```

   Skim the old body only for durable keepers (stacked-on note, requested validation); treat the rest as untrusted.
2. **Draft.** Apply the content test; the body reads as a fresh answer to why the diff exists today, not a changelog. Drop stale and dev-journey prose, keep template structure and durable context, and retitle if the diff has shifted from the original intent.
3. **Apply** via [an API edit](#applying-edits).
4. **Don't touch unrelated state** — no new commits, rebase, base change, re-requested reviews, or close/reopen just because you're editing the body.

## Applying edits

Prefer an app-native PR tool if the session exposes one (GitHub MCP `update_pull_request`, or a host equivalent) — REST PATCH under the hood, no SAML or `read:org` scope. Write bodies to a git-local scratch file (`git rev-parse --git-path copilot-pr-body.md`) to dodge shell escaping, and include the signature block.

If there's no app-native tool, `gh pr create` / `gh pr edit --body-file` work — but `gh pr edit` routinely fails on the local token with an opaque `read:org` scope error. On that failure, PATCH directly (no extra scope):

```bash
jq -Rs '{body: .}' < body.md | gh api -X PATCH /repos/<owner>/<repo>/pulls/<num> --input -
```

The same pattern works for `title`, `base`, and `state`.

The Pull Request Authoring Gate fires on any PR mutation done this way — `gh pr edit`/`create`, `gh api …/pulls/…`, `curl` — even through bash. This skill must be loaded first; don't type the command and hope.

## Edge cases

- **No changes:** check for an existing PR; if unpushed commits exist, push and create.
- **PR already exists:** push new commits — it updates automatically.
- **On the default branch:** create a feature branch first.

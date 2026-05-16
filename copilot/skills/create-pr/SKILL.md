---
name: create-pr
description: Use when creating a GitHub pull request from current changes, especially when commits, PR templates, concise descriptions, or review-before-posting are needed.
user-invocable: true
---

# Create Pull Request

Create a PR from the current branch. Use session context to write the description — don't re-analyze diffs you already understand.

If an app-native PR creation tool is available, prefer it over shelling out to `gh`. Use this workflow to prepare the branch, commits, title, and body either way.

## Cardinal rules

- **Describe the final state, not the dev journey.** The reviewer is reading the final diff. Do not narrate how the branch got there.
- **Do not include process status as prose.** Skip standalone `make lint` / `make test` / CI green-red status paragraphs, force-push notes, "had a fixup", "switched approach from X to Y", and self-review findings already fixed. The reviewer can see CI status in GitHub and read the final diff.
- **Use the PR template when one exists.** Fill every section or ask for the missing information.
- **Keep trailers out of PR bodies.** `Co-authored-by:` belongs in git commit messages only. PR bodies end with the GitHub Posting Protocol signature block from the global instructions.

## Workflow

### 1. Assess state

```bash
git rev-parse --abbrev-ref HEAD && git status --short && git remote get-url origin
```

Extract owner/repo from the remote URL. Determine the default branch:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

If on the default branch, create a feature branch first.

### 2. Commit

Group changes into logical, atomic commits. Prefer fewer commits — one is fine if the change is cohesive. Keep subject lines under 72 chars. Be specific.

```bash
git add -A && git commit -m "descriptive message"
```

### 3. Push

```bash
git push -u origin HEAD
```

Do not merge or rebase the base branch just because it has moved. Only update from the base branch when required by conflicts, failing checks, branch protection, or explicit user request. Prefer the repo's normal history policy.

### 4. Find the PR template

```bash
for f in \
  .github/pull_request_template.md \
  .github/PULL_REQUEST_TEMPLATE.md \
  docs/pull_request_template.md \
  pull_request_template.md \
  PULL_REQUEST_TEMPLATE.md \
  .github/PULL_REQUEST_TEMPLATE/*.md; do
  [ -f "$f" ] && echo "Found: $f"
done
```

If a template is found, read it and use its structure. If multiple templates exist, pick the most appropriate one for the change type.

**If a template exists, you MUST use it.** Fill in every section. Do not skip sections or leave placeholders.

### 5. Detect chain-stacking

When a project ships as a stack of dependent PRs (PR k+1 builds on PR k's diff), **base PR k+1 on PR k's head branch, not the default branch**. The reviewer then sees only what k+1 adds on top of k, with no spurious conflicts from default-branch drift. Retarget to the default branch (or let GitHub auto-rebase) only when PR k merges.

Detect it before drafting:

```bash
default_branch=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
# If HEAD is not a descendant of the default branch, it's probably stacked.
if ! git merge-base --is-ancestor "origin/$default_branch" HEAD; then
  # Find a branch with an open PR that *is* an ancestor of HEAD.
  for ref in $(gh pr list --state open --json headRefName --jq '.[].headRefName'); do
    git merge-base --is-ancestor "origin/$ref" HEAD 2>/dev/null && echo "stacked on: $ref"
  done
fi
```

If a stacked candidate is found, surface it: "This branch is stacked on `<branch>` (open PR #N). Base on `<branch>` or on `<default>`?" Default to the stacked base; offer the default branch as the override.

When basing on a prior PR's head, add a line near the top of the PR body:

```markdown
> Stacked on #<prior-pr> — will be retargeted to `<default>` when that merges.
```

Pass `--base <stacked-branch>` to `gh pr create`. After the upstream PR merges, retarget with `gh pr edit <num> --base <default>`.

### 6. Draft the PR

**Title:** Concise summary. Follow repo conventions if any (e.g., `feat:`, `fix:`).

**Body:** Be VERY CONCISE. Every sentence must earn its place.

- If a template exists: fill each section with 1-3 sentences max. Use bullet points. No filler.
- If no template: write a short description covering what changed and why. Skip "how" unless non-obvious.
- Reference issues if the branch name or context suggests one (e.g., `Fixes #123`).
- Never pad with obvious information. The reviewer can read the diff.
- **Describe the final state, not the dev journey.** If a non-obvious decision needs context, state it as the current rationale ("uses Y because Z"), not as a fix-up story.
- **Trailer hygiene.** `Co-authored-by:` belongs in **git commit messages only**, never in a PR body, issue, or comment. PR bodies end with the GitHub Posting Protocol signature block from the global instructions — nothing else.
- Before posting with `gh` or any GitHub tool, append the required GitHub Posting Protocol signature from the global instructions. Verify the final PR body ends with that signature block.

**If you're unsure how to fill out a template section**, ask the user rather than guessing. Be specific about what you need to know.

### 7. Review before posting

When interactive, show the user the full PR title and body before creating it. Ask for confirmation or edits. Do not create the PR until the user approves.

When non-interactive, create the PR only if the user already asked for one and all required fields are known. Prefer a draft PR when there is any uncertainty. If required template fields are unknown, stop with the prepared title/body instead of guessing.

### 8. Create the PR

If no app-native PR creation tool is available, write the body to a git-local scratch file to avoid shell escaping issues:

```bash
body_file="$(git rev-parse --git-path copilot-pr-body.md)"
# write the complete body, including the GitHub Posting Protocol signature, to "$body_file"
gh pr create --title "title" --body-file "$body_file" --base <default-branch>
rm "$body_file"
```

Display the PR URL after creation.

## Tracking-issue convention

For multi-PR rollouts coordinated by an umbrella tracking issue, some teams require the tracker to stay open until the terminal PR lands, which means **none** of the stack's PRs may use `Closes` / `Fixes` / `Resolves`. If the user mentions a tracking or umbrella issue, ask whether that convention applies. If it does, add a blockquote near the top of the body and skip the closing keywords:

```markdown
> Tracking: [#NNNN](https://github.com/<owner>/<repo>/issues/NNNN) (multi-PR rollout — this PR intentionally does not use `Closes`; the tracker stays open until the final PR lands)
```

Do not add this blockquote speculatively; it's a team-level convention, not a default.

## Edge cases

- **No changes:** Check for existing PR (`gh pr view`). If one exists, nothing to do. If unpushed commits exist, push and create.
- **PR already exists:** Push new commits — the PR updates automatically. Inform the user.
- **On default branch:** Create a feature branch, then proceed.
- **`gh pr edit --body-file` fails with a scope error.** `gh pr edit` requires `read:org` on the local token; many installs don't have it and the failure is opaque. Fall back to the REST API, which needs no extra scope:

  ```bash
  jq -Rs '{body: .}' < body.md \
    | gh api -X PATCH /repos/<owner>/<repo>/pulls/<num> --input -
  ```

  Same pattern works for `title`, `base`, and `state` fields.

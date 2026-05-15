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

### 5. Draft the PR

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

### 6. Review before posting

When interactive, show the user the full PR title and body before creating it. Ask for confirmation or edits. Do not create the PR until the user approves.

When non-interactive, create the PR only if the user already asked for one and all required fields are known. Prefer a draft PR when there is any uncertainty. If required template fields are unknown, stop with the prepared title/body instead of guessing.

### 7. Create the PR

If no app-native PR creation tool is available, write the body to a git-local scratch file to avoid shell escaping issues:

```bash
body_file="$(git rev-parse --git-path copilot-pr-body.md)"
# write the complete body, including the GitHub Posting Protocol signature, to "$body_file"
gh pr create --title "title" --body-file "$body_file" --base <default-branch>
rm "$body_file"
```

Display the PR URL after creation.

## Edge cases

- **No changes:** Check for existing PR (`gh pr view`). If one exists, nothing to do. If unpushed commits exist, push and create.
- **PR already exists:** Push new commits — the PR updates automatically. Inform the user.
- **On default branch:** Create a feature branch, then proceed.

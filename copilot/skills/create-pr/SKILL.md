---
name: create-pr
description: Create a pull request from current changes. Finds and fills PR templates, commits logically, and lets you review before posting.
user-invocable: true
---

# Create Pull Request

Create a PR from the current branch. Use session context to write the description — don't re-analyze diffs you already understand.

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

If the branch is behind the base, merge (don't rebase unless asked):

```bash
git fetch origin main && git merge origin/main
```

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

**If you're unsure how to fill out a template section**, ask the user rather than guessing. Be specific about what you need to know.

### 6. Review before posting

**ALWAYS** show the user the full PR title and body before creating it. Ask for confirmation or edits. Do not create the PR until the user approves.

### 7. Create the PR

Write the body to a temp file to avoid shell escaping issues:

```bash
gh pr create --title "title" --body-file /tmp/pr-body.md --base main
rm /tmp/pr-body.md
```

Display the PR URL after creation.

## Edge cases

- **No changes:** Check for existing PR (`gh pr view`). If one exists, nothing to do. If unpushed commits exist, push and create.
- **PR already exists:** Push new commits — the PR updates automatically. Inform the user.
- **On default branch:** Create a feature branch, then proceed.

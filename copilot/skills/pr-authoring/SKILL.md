---
name: pr-authoring
description: Use when creating a GitHub pull request, or when updating an existing PR's title or body so it matches what the code actually does.
user-invocable: true
---

# Authoring a Pull Request

Author or refresh a PR's title and body so they describe the final diff, not the dev journey. Same cardinal rules apply whether you're creating a new PR or rewriting an existing one that has drifted from the code.

If an app-native PR creation/edit tool is available in the current session, prefer it over shelling out to `gh`. Most app-native edit tools use REST PATCH under the hood and sidestep the SAML / `read:org` scope error that `gh pr edit` routinely hits on the local token. Names vary by host (GitHub MCP exposes `update_pull_request`; some apps ship an internal equivalent) — use whatever the session offers. Use this workflow to prepare the branch, commits, title, and body either way.

## Cardinal rules

- **Describe the final state, not the dev journey.** The reviewer is reading the final diff. Do not narrate how the branch got there.
- **Do not include process status as prose.** Skip standalone `make lint` / `make test` / CI green-red status paragraphs, force-push notes, "had a fixup", "switched approach from X to Y", and self-review findings already fixed. The reviewer can see CI status in GitHub and read the final diff.
- **Use the PR template when one exists.** Fill every section or ask for the missing information.
- **Keep trailers out of PR bodies.** `Co-authored-by:` belongs in git commit messages only. PR bodies end with the GitHub Posting Protocol signature block from the global instructions.
- **Re-ground in the diff before rewriting an existing PR.** Title/body drift is common when an agent iterates without re-reading the final diff. Refuse to update from memory alone.

## Decide: create or update

Run `gh pr view --json number,title,body,baseRefName 2>/dev/null` from the branch. If it returns a PR, this is an **update**; jump to [Update an existing PR](#update-an-existing-pr). Otherwise this is a **create**; follow the creation workflow.

## Workflow (create)

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

Pass `--base <stacked-branch>` to `gh pr create`. After the upstream PR merges, retarget using an app-native PR edit tool if one is available (no `read:org` required). Only fall back to `gh pr edit <num> --base <default>` if no app-native tool is available, and expect the REST API fallback from [Edge cases](#edge-cases) if that errors on scopes.

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

## Update an existing PR

Use this when an agent has been iterating on a PR and the title or body no longer matches the code. The goal is to rewrite both so they describe the **current** final diff, concisely.

### 1. Re-ground in the actual diff

Do not rewrite from memory or from the existing body. Read the real diff against the PR's base:

```bash
num=$(gh pr view --json number --jq .number)
base=$(gh pr view --json baseRefName --jq .baseRefName)
git fetch origin "$base"
git diff --stat "origin/$base"...HEAD
git log --oneline "origin/$base"..HEAD
git diff "origin/$base"...HEAD          # full diff; skim for surprises
```

Skim the existing body too — note any sections worth keeping (tracking-issue blockquote, stacked-on note, validation notes the reviewer asked for), but treat everything else as untrusted.

### 2. Draft the new title and body

Apply the cardinal rules. The body should read like a fresh description of what the diff does today, not a changelog of how the PR evolved.

- Drop anything that no longer matches the code.
- Drop dev-journey prose ("originally tried X, then switched to Y", "fixup after review", "addressed feedback in commit abc123").
- Keep the PR template structure if one exists; fill each section against the current diff.
- Preserve durable context the reviewer needs (stacked-on note, tracking-issue blockquote, deliberate non-goals).
- End with the GitHub Posting Protocol signature block.

For the title: match the diff's main change. If the title still describes the original intent but the diff has narrowed or shifted, retitle.

### 3. Show the user before posting

Show the proposed title and body diff (old vs new) and ask for approval. Do not push edits silently.

### 4. Apply the update

Prefer an app-native PR edit tool if one is available in this session (REST PATCH under the hood, no SAML or `read:org` scope required). Names vary by host (GitHub MCP: `update_pull_request`; some apps ship an internal equivalent). Pass the new title and body directly to whatever tool the session exposes.

If no app-native tool is available, try `gh pr edit` — though it routinely fails on the local token with an opaque `read:org` scope error:

```bash
body_file="$(git rev-parse --git-path copilot-pr-body.md)"
# write the new body, including the signature block, to "$body_file"
gh pr edit "$num" --title "new title" --body-file "$body_file"
rm "$body_file"
```

If `gh pr edit` fails with a scope error, use the REST API fallback from [Edge cases](#edge-cases).

### 5. Do not touch unrelated state

- Do not push new commits, rebase, or change the base just because you're editing the body.
- Do not re-request reviews unless the user asks.
- Do not close/reopen the PR.

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
- **`gh pr edit --body-file` fails with a scope error.** `gh pr edit` requires `read:org` on the local token; many installs don't have it and the failure is opaque. Prefer an app-native PR edit tool (REST PATCH, no extra scope required) if the session exposes one. Otherwise fall back to the REST API directly, which also needs no extra scope:

  ```bash
  jq -Rs '{body: .}' < body.md \
    | gh api -X PATCH /repos/<owner>/<repo>/pulls/<num> --input -
  ```

  Same pattern works for `title`, `base`, and `state` fields.

## Common mistakes

- **Reaching for `gh pr edit` first.** It needs `read:org` on the local token and routinely fails with an opaque scope error. Default to an app-native PR edit tool if the session exposes one (REST PATCH, no extra scope), otherwise the REST API directly. `gh pr edit` is the last resort.
- **Treating `bash gh pr edit …` as a way around the authoring gate.** The Pull Request Authoring Gate fires on any PR mutation — including `gh pr edit`, `gh pr create`, `gh api … /pulls/…`, or `curl` against the pulls API — even when invoked through bash. Load this skill first; do not type the command and hope.
- **Rewriting body from memory.** When updating an existing PR, always re-ground in the actual diff against the base ref first. Memory drifts after a few iterations.
- **Padding the body with process status.** CI results, force-push notes, "switched approach from X to Y", and self-review findings already fixed do not belong in the body. The reviewer sees CI in GitHub and reads the final diff.

---
name: pr-update-base-branch
description: Use when merging an updated base branch into a PR branch to resolve drift, especially when the PR may be chain-stacked on another PR rather than the repo default.
---

# Merging Base into a PR

Update a PR branch by merging its **actual** base ref, not a hardcoded default branch. Resolve recurring stacked-PR conflicts deterministically and verify before committing.

## When to use

- The user asks to "merge the latest base", "update from main", "sync with base", or to resolve drift on an open PR.
- A PR has failing checks or "this branch is out of date" warnings.
- A chain-stacked PR's upstream just merged and the local branch needs to pick up that merge.

Do not use this skill to rebase, force-push history rewrites, or close-and-recreate PRs.

## Rules

### 1. Pull the actual base from the PR, never assume `main`

App-generated prompts often hardcode "base branch: `origin/main`". Ignore that and ask the PR:

```bash
base=$(gh pr view <num> --json baseRefName --jq .baseRefName)
git fetch origin "$base"
```

For chain-stacked PRs the base is the prior PR's head branch, not the repo default. Merging the wrong ref creates noisy commits and can re-introduce conflicts the upstream PR already resolved.

**Guard:** if `$base` is not the repo default, do not silently merge the default branch instead. Use `$base`. Only fall back to the default branch if the user explicitly overrides.

### 2. Enable `git rerere` once per repo

```bash
git config rerere.enabled true
```

Recurring conflicts (typical in a stack where the same files are touched in multiple PRs) get auto-resolved on subsequent merges using your prior resolution. Enable this before the first merge of a stack so the resolutions are recorded.

### 3. Merge, then verify before resolving

```bash
git merge "origin/$base"
```

On conflict, do not blanket-pick a side. For each conflicted file, inspect both stages:

```bash
# stage 2 = ours (HEAD), stage 3 = theirs (incoming base)
git show :2:<file> | <inspect>
git show :3:<file> | <inspect>
```

### 4. Common conflict shapes

**a) "Ours is strictly newer"** — when the feature branch has N commits stacked on the base, and the base picks up commits that overlap with that work (e.g. the prior PR in the stack merged a subset of what HEAD already has), the conflicting hunks in overlapping files resolve with `--ours` because HEAD strictly supersedes base for that surface.

Verify the assumption before using `--ours`. Pick a concrete marker that should be present in ours and absent (or different) in theirs — e.g. a removed type, a renamed function, a deleted module — and check both stages:

```bash
git show :2:<file> | grep -c "<expected-marker-in-ours>"
git show :3:<file> | grep -c "<expected-marker-in-theirs>"
```

If the counts match the expectation, resolve:

```bash
git checkout --ours <files>
git add <files>
```

**b) `modify/delete` from a sub-split** — base deleted a file you modified, usually because the upstream PR split or relocated it. Find where it went before deciding:

```bash
git log --oneline --diff-filter=D origin/$base -- <file>
```

Usually accept the deletion with `git rm <file>` and adopt the new structure. Restoring the file is rare; call it out explicitly when you do.

After resolving (either shape), immediately run the language's typecheck (`cargo check`, `tsc --noEmit`, `go build ./...`, etc.) to catch any semantic conflict the file-level resolution missed. Run relevant tests. Commit only after both pass.

### 5. Scan merged commits for tooling drift

Before pushing, look at what the merge brought in beyond source code:

```bash
git log --stat HEAD@{1}..HEAD -- '*.toml' '*.lock' 'package.json' 'bun.lock' 'go.mod' 'go.sum' '.tool-versions' 'rust-toolchain*' '.eslintrc*' '.rubocop.yml'
```

If dependency manifests or lockfiles changed, re-run the install step (`bun install`, `cargo build`, `bundle install`, etc.) before validating — otherwise the typecheck runs against stale deps. If toolchain or lint config changed, flag it in the commit/PR comment so new errors read as drift, not regressions you introduced.

### 6. Push and let CI re-verify

```bash
git push
```

No force-push. Merge commits are fine; they're the honest record of the base update.

## Common mistakes

- Trusting the prompt template's "base branch: `origin/main`" instead of querying `gh pr view --json baseRefName`. The two diverge for every stacked PR.
- Resolving conflicts with `--ours` or `--theirs` without spot-checking the stages first.
- Skipping the post-resolve typecheck because the file-level merge "looked clean". File-level resolutions routinely miss semantic conflicts (a caller in one file, a signature change in another).
- Forgetting to enable `git rerere`, then re-resolving the same three-file conflict on every merge in a long-running stack.
- Force-pushing after the merge to "clean up history". The merge commit is the artifact reviewers and CI expect.
- Validating without re-installing after a lockfile bump came in with the merge — the typecheck passes against stale deps, then CI explodes on fresh ones.
- Reflexively restoring a `modify/delete` file instead of checking whether the upstream PR moved or split it.

---
name: deps-update
description: Use when updating project dependencies, processing Dependabot PRs or alerts, grouping dependency updates, resolving breakage, or preparing dependency update pull requests.
user-invocable: true
---

# Updating Dependencies

Update dependencies conservatively, one coherent ecosystem at a time, with risk assessment before changes and validation before PR handoff.

## Workflow

### 1. Assess repository state

Identify the repo, current branch, default branch, package ecosystems, and existing update automation.

```bash
git remote get-url origin
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
git status --short
find . -maxdepth 4 \( \
  -name Cargo.toml -o \
  -name rust-toolchain.toml -o \
  -name go.mod -o \
  -name package.json -o \
  -name pnpm-lock.yaml -o \
  -name yarn.lock -o \
  -name bun.lockb -o \
  -name Gemfile -o \
  -name Dockerfile -o \
  -path './.github/workflows/*.yml' -o \
  -path './.github/workflows/*.yaml' \
\) -print
```

If the repo has explicit dependency update docs or scripts, follow those over this generic workflow.

### 2. Gather dependency intelligence

Prefer existing Dependabot context:

```bash
gh pr list --author 'app/dependabot' --state open --json number,title,baseRefName,headRefName,labels --limit 100
gh api /repos/{owner}/{repo}/dependabot/alerts --jq '[.[] | select(.state=="open") | {number: .number, package: .security_vulnerability.package.name, ecosystem: .security_vulnerability.package.ecosystem, severity: .security_advisory.severity, summary: .security_advisory.summary}]'
```

If Dependabot is unavailable or incomplete, use native tools:

| Ecosystem | Discovery/update intelligence |
|---|---|
| Cargo | `cargo update --dry-run`, inspect `Cargo.toml` and `Cargo.lock` |
| Rust toolchain | inspect `rust-toolchain.toml`, release notes for major/minor jumps |
| Go modules | `go list -u -m all` in each `go.mod` directory |
| npm | `npm outdated --json` in each `package.json` directory |
| pnpm | `pnpm outdated --format json` |
| Yarn | `yarn outdated --json` |
| Bun | `bun outdated` if available |
| Bundler | `bundle outdated` in each `Gemfile` directory |
| GitHub Actions | Dependabot PRs/alerts, then workflow `uses:` entries |
| Docker | Dependabot PRs/alerts first; registry auth often blocks direct queries |

Summarize updates by ecosystem, security severity, existing PRs, and risk.

### 3. Risk assessment gate

Before applying updates, call out and usually split or defer:

- major version bumps;
- runtime/toolchain changes;
- peer dependency cascades;
- packages with wide blast radius;
- multiple unrelated major bumps in one PR;
- git-pinned revisions;
- generated-code dependencies;
- private registries or images where tooling cannot verify available versions.

Ask the user before taking high-risk upgrades. For low-risk patch/minor updates and security fixes, proceed with the smallest coherent group.

### 4. Apply one ecosystem at a time

Start from the repo's intended base branch, usually the default branch unless repo docs say otherwise. Create a feature branch if needed.

Use the package manager's normal update path and preserve lockfiles. Do not edit manifests without regenerating the lockfile.

| Ecosystem | Typical update command |
|---|---|
| Cargo | `cargo update` or targeted `cargo update -p <package>` |
| Go | `go get -u ./... && go mod tidy` |
| npm | `npm update` or targeted `npm install <pkg>@<version>` |
| pnpm | `pnpm update` or targeted `pnpm update <pkg>` |
| Yarn | `yarn upgrade` or repo-preferred equivalent |
| Bun | `bun update` |
| Bundler | `bundle update` or targeted `bundle update <gem>` |
| GitHub Actions | edit `uses:` versions from trusted update source |
| Docker | edit `FROM` tags/digests from trusted update source |

### 5. Validate

Use repo-native validation. Discover commands from README, Makefile, package scripts, CI config, or language conventions.

Common checks:

```bash
cargo check
cargo test
go test ./...
npm test
npm run build
pnpm test
pnpm build
bundle exec rake
```

Run only commands that exist. If validation fails, read the error, fix real breakage, and rerun. Stop and ask if the failure is ambiguous, high-risk, or still unresolved after focused fixes.

### 6. Prepare the PR

The PR body should include:

- ecosystem and packages updated;
- old and new versions when available;
- security alerts resolved;
- high-risk changes called out;
- code changes required for compatibility;
- validation commands run;
- Dependabot PRs superseded.

If posting the PR with `gh`, follow the GitHub Posting Protocol in the global instructions.

## Guidelines

- One ecosystem per PR unless the repo intentionally groups them.
- Security alerts take priority.
- Smaller safe updates beat ambitious mixed updates.
- Do not push broken dependency updates.
- Do not bypass lockfiles.
- Do not assume the base branch is `main` or `dev`; discover it.
- Prefer repo-specific dependency docs over this generic guide.

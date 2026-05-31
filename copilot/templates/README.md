# Skill templates

Starter skills for new repositories. Copy a template into the repo's skills
directory (e.g. `.github/skills/<name>/SKILL.md` or `skills/<name>/SKILL.md`,
matching whatever convention that repo already uses), then prune sections that
do not apply and fill in the project-specific extension stubs.

Templates are not symlinked into `~/.copilot/skills/`. They are scaffolding for
repo-local skills, not active user-level skills.

## Relationship to user-level fallback skills

Each language template here has a sibling **user-level fallback skill** under
`copilot/skills/<lang>/` (e.g. `code-rust`, `code-go`). They share source
material but play different roles:

| Artifact | Lives in | Synced? | When it fires | Opinion level |
|---|---|---|---|---|
| Fallback skill (`code-rust`, `code-go`) | `copilot/skills/<lang>/` | yes — symlinked into `~/.copilot/skills/` | any repo without its own language skill | opinion-light, generic to any project |
| Template (`rust-coding-skill`, `go-coding-skill`) | `copilot/templates/` | no — scaffolding only | when you `cp -r` it into a specific repo | opinion-heavy, with project-specific extension stubs |

The two **intentionally drift**. The fallback is hand-trimmed for portability
across any project in that language. The template stays closer to the original
opinionated source and keeps the project-specific stubs that a real repo will
want to fill in. Don't try to keep them mechanically in sync — the split is the
point.

When a repo grows its own copy of the template, it takes precedence over the
user-level fallback at discovery time.

## Available templates

- `rust-coding-skill/` — opinionated Rust style and discipline rules distilled
  from the blackbird, gh-blackbird, and github-app skills. Drop into any Rust
  project as a starting point.
- `go-coding-skill/` — opinionated Go style and discipline rules adapted from
  the `github/blackbird-mw` skill. Drop into any Go project as a starting
  point.

## How to use

```bash
cp -r ~/github/dotfiles/copilot/templates/<template-name> /path/to/repo/<skills-dir>/<template-name>
$EDITOR /path/to/repo/<skills-dir>/<template-name>/SKILL.md
```

Edit the description to match the repo, delete sections that do not apply, and
fill in the "Project-specific extensions" stubs with the repo's runtime
wrappers, banned macros, ID newtypes, and similar local conventions.

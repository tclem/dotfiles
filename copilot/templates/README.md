# Skill templates

Starter skills for new repositories. Copy a template into the repo's skills
directory (e.g. `.github/skills/<name>/SKILL.md` or `skills/<name>/SKILL.md`,
matching whatever convention that repo already uses), then prune sections that
do not apply and fill in the project-specific extension stubs.

Templates are not symlinked into `~/.copilot/skills/`. They are scaffolding for
repo-local skills, not active user-level skills.

## Available templates

- `rust-coding-skill/` — opinionated Rust style and discipline rules distilled
  from the blackbird, gh-blackbird, and github-app skills. Drop into any Rust
  project as a starting point.

## How to use

```bash
cp -r ~/github/dotfiles/copilot/templates/rust-coding-skill /path/to/repo/<skills-dir>/rust-coding-skill
$EDITOR /path/to/repo/<skills-dir>/rust-coding-skill/SKILL.md
```

Edit the description to match the repo, delete sections that do not apply, and
fill in the "Project-specific extensions" stubs with the repo's runtime
wrappers, banned macros, ID newtypes, and similar local conventions.

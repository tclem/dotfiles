---
name: daily-handoff
description: "Use when authoring a daily Slack handoff for the Blackbird team - status-first narrative with indented PR bullets using :merged: / :review: emoji."
user-invocable: true
---

# Daily Handoff

Author a daily handoff message for the Blackbird team, formatted for Slack. Output a fenced markdown block the user can copy directly.

## Gather activity

A handoff covers activity since the last one — typically the last 24 hours, but extend the window back across weekends and holidays (e.g. on Monday, look back to Friday morning). Ask the user if the lookback window isn't obvious.

**Bulleted PRs are always the user's own PRs.** `:merged:` and `:review:` both refer to PRs the user authored. PRs the user only reviewed/approved/commented on are **not** bulleted.

**Personal-account PRs are excluded.** The handoff is for the Blackbird team, so PRs in the user's personal account (`tclem/*`) are side projects and do **not** appear in the handoff. Work in any *organization* (`github/*` is typical, but the user occasionally contributes to other orgs too) is eligible. When in doubt about an unfamiliar org, ask the user rather than dropping it.

**Don't scope to one repo.** The user's work spans several org repos in the same week. Every query below is author-scoped, not repo-scoped — keep it that way.

1. **Merged-in-window authored PRs.** The reliable query uses `--merged-at` (catches PRs created earlier but merged during the window):
   ```bash
   gh search prs --author=@me --merged \
     --merged-at=">=$(date -v-1d -u +%Y-%m-%dT%H:%M:%SZ)" \
     --json url,title,repository --limit 100
   ```
   `gh-log` can also produce a merged list, but its `created:` filter misses PRs that were created before the window and merged inside it — prefer `gh search --merged-at`. Filter the results to drop any PR whose `repository.nameWithOwner` starts with `tclem/`.

2. **Still-open authored PRs** (for `:review:` bullets):
   ```bash
   gh search prs --author=@me --state=open \
     --json url,title,repository,updatedAt --limit 50
   ```
   Filter to PRs updated in the window or that the user is actively pushing. Drop `tclem/*` PRs. Drop dependabot / auto-merge noise unless the user calls it out.

3. **Authored issues and discussions.** Design write-ups, investigations, and posts are first-class handoff content and often *are* the day's output. `gh search` has no discussion support, so use GraphQL:
   ```bash
   gh search issues --author=@me --created=">=YYYY-MM-DD" \
     --json url,title,repository --limit 30

   gh api graphql -f query='
   {
     search(query: "author:tclem is:discussion updated:>=YYYY-MM-DD", type: DISCUSSION, first: 10) {
       nodes { ... on Discussion { title url updatedAt repository { nameWithOwner } } }
     }
   }'
   ```
   Link these inline in the narrative bullet rather than as `:merged:`/`:review:` bullets — those two emoji mean PRs.

4. **Session history**, for work that produced no artifact at all — an investigation, a review pass, a doc refined but not yet posted. Query the local session store:
   ```sql
   SELECT repository, summary, updated_at FROM sessions
   WHERE substr(updated_at,1,10) >= date('now','-1 days')
     AND repository IS NOT NULL
   ORDER BY updated_at DESC LIMIT 30
   ```
   Treat `summary` as a raw hint, not prose to reuse — it's often the verbatim kickoff prompt. Use it to *remember* a work stream, then write the narrative yourself. This is the same data behind `/chronicle standup`.

Prefer what you already know from the current session over re-fetching.

## Structure the handoff

The handoff is **status-first**, with PRs as supporting evidence — not the other way around. Each top-level bullet is a narrative paragraph about a work stream, blocker, or meta update; PR bullets nest underneath.

### Top-level bullets (rough order)

1. **Meetings / context.** A bullet listing meetings and notable conversations. The user will usually rewrite this, but take a first pass from session context if you have it — don't just emit a generic "random 1:1s and meetings" placeholder.
2. **On-call / ops** (if the user is on-call). A narrative capturing the shape of the day — how busy, what landed, what didn't, who helped. Credit collaborators with `@handle` and reference channels with `#channel`.
3. **Active work streams**, one bullet per theme. Lead with story: what happened, what's blocked, what's next. Name blockers explicitly — who you've asked, what you're waiting on ("I'm blocked here"). PRs nest underneath.
4. **Incidents / investigations** if any, with links to the incident issue and any security engagement.

### PR bullet format

Nest PR bullets under the narrative bullet they support. Use **four leading spaces** before nested PR bullets; two spaces can render inconsistently in Slack.

```
* Narrative paragraph for this theme — status, blockers, what's next.
    * :merged: [<title>](https://github.com/org/repo/pull/N)
    * :review: [<title>](https://github.com/org/repo/pull/N) -> optional inline commentary
```

- `:merged:` — PR authored by user, merged in window.
- `:review:` — PR authored by user, still open.
- Inline commentary after a PR bullet (e.g. `-> will try this out tomorrow, low priority.`) is encouraged when useful.
- Use markdown link syntax so Slack renders titles as clickable links.

### What to drop

- **Personal-account PRs** (`tclem/*`). These are side projects and are excluded by default. Org-owned repos (`github/*` and any other orgs the user contributes to) are eligible — only the personal account is filtered.
- **Yesterday's already-merged work** that's no longer in flight. Focus on what's active *now*.
- **Dependabot / auto-generated / trivial chore PRs**, unless the user flags them.
- **PRs you only reviewed or approved.** GitHub's `commenter:` search qualifier includes approvals, so `gh-log`'s "commented on" bucket conflates real discussion with routine approvals — use it only as narrative hints, never as bullets. Verify with `gh pr view <url> --comments` before framing anything as "discussing."
- **"Misc" catch-all sections.** If a PR doesn't fit a theme, fold it into an existing narrative or drop it.

## Output format

One fenced code block, starting with `Handoff:`:

````
```
Handoff:
* Meetings / context line (specific if possible).

* <On-call narrative if applicable — how the day went, what landed, what didn't, who helped>.

* <Theme 1 narrative: status, blockers, what's next>:
    * :merged: [<title>](https://github.com/org/repo/pull/N)
    * :review: [<title>](https://github.com/org/repo/pull/N)

* <Theme 2 narrative, with explicit blockers if any>:
    * :review: [<title>](https://github.com/org/repo/pull/N) -> optional inline note
```
````

## Save the handoff

After producing the fenced block, always save the handoff to the `tclem/notes` repo without asking first.

Use the user's notes checkout even when the current session is running in another repo. Handoffs live at the repo root:

```text
~/github/notes/YYYY-MM-DD-handoff-NN.md
```

Determine `NN` by finding the highest existing handoff number and incrementing it:

```bash
find ~/github/notes -maxdepth 1 -name '*-handoff-*.md' -print |
  sed -E 's/.*-handoff-([0-9]+)\.md$/\1/' |
  sort -n |
  tail -1
```

If the latest file is `2026-05-11-handoff-53.md`, the next file is `YYYY-MM-DD-handoff-54.md` using today's date.

Saved file format:

```markdown
# YYYY-MM-DD handoff NN

Tags: #handoff #project-tag

<handoff fenced block, verbatim>
```

The H1 repeats the date and number from the filename — older files use a bare `# Handoff NN`, but don't copy that.

Infer project tags from the handoff content, e.g. `#blackbird`, `#github-app`, `#copilot`, or other obvious project names. Keep tags lowercase and hyphenated when needed. Preserve the fenced block verbatim in the saved file so the note exactly matches what the user can paste into Slack.

## Style notes

- Match the user's voice: casual, first-person, specific.
- Blockers, non-progress ("I did *not* get to X"), and help from colleagues are first-class content — name them explicitly.
- Short narrative sentences. Don't pad.
- Don't invent context. If a PR's purpose isn't clear from its title or session, ask or omit.

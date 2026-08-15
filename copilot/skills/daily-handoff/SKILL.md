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
   Link these inline in the theme bullet rather than as `:merged:`/`:review:` bullets — those two emoji mean PRs.

4. **Session history**, for work that produced no artifact at all — an investigation, a review pass, a doc refined but not yet posted. Query the local session store:
   ```sql
   SELECT repository, summary, updated_at FROM sessions
   WHERE substr(updated_at,1,10) >= date('now','-1 days')
     AND repository IS NOT NULL
   ORDER BY updated_at DESC LIMIT 30
   ```
   Treat `summary` as a raw hint, not prose to reuse — it's often the verbatim kickoff prompt. Use it to *remember* a work stream, then write the narrative yourself. This is the same data behind `/chronicle standup`.

5. **Slack activity**, for the work that never became a PR or issue — decisions, help from teammates, incident chatter, and the meetings/context that opens the handoff. The handoff is *posted* to Slack, so Slack is also where much of the day's discussion already lives. Search your own recent messages with the `slack_search_public` tool, using the current user ID the tool reports:
   ```
   query: "from:<@SELF> after:YYYY-MM-DD"   sort: "timestamp"
   ```
   Narrow with a topic term (`from:<@SELF> <project> after:...`), or drop `from:` to catch threads where a teammate looped you in (`in:#channel to:<@SELF> after:...`). Mine Slack the same way as session history: a memory aid, never prose to copy. Pull collaborator credits (`@handle`), channel references (`#channel`), blockers, and the meeting names and conversations that open the handoff — then write the narrative yourself. Slack also tells you what to *cut*: anything already posted in the channel the handoff goes to should be linked, not restated. Prefer `slack_search_public`; only reach for the private-channel variant when the work genuinely lived in a private channel and the user is okay searching it.

Prefer what you already know from the current session over re-fetching.

## Structure the handoff

The handoff is **status-first**, with PRs as supporting evidence — not the other way around. Each top-level bullet is one sentence about a work stream or blocker; PR bullets nest underneath.

### Top-level bullets (rough order)

**Never open with a summary of the day.** No scene-setting, no characterizing bullet ("Prototype-heavy day: four parallel spikes…", "Half day — afternoon in the city"). The handoff starts at the first meeting and goes straight to work.

1. **Meetings / context.** **One bullet per meeting**, bare name, no verb or framing — `* Town Hall`, `* Team sync`. A notable conversation gets one clause of substance and the person's handle: `* Good, long conversation with @handle about local search.` Take a first pass from session context and Slack (step 5); don't emit a generic "random 1:1s and meetings" placeholder.
2. **On-call / ops** (if the user is on-call). A narrative capturing the shape of the day — how busy, what landed, what didn't, who helped. Reference channels with `#channel`.
3. **Active work streams**, one bullet per theme — see [Writing a theme bullet](#writing-a-theme-bullet). Name blockers explicitly: who you've asked, what you're waiting on ("I'm blocked here"). PRs nest underneath.
4. **Incidents / investigations** if any, with links to the incident issue and any security engagement.

### Writing a theme bullet

- **One sentence.** Not three, not a paragraph. State what happened and stop.
- **Open with the handle of whoever cares** when the bullet *is* the ask: `* @handle, I'm going to drop the unused symbol fields:`. If the ask already lives in a linked thread where you cc'd them, link the thread and drop the handles — don't ask twice.
- **Put the most important link in the sentence**, not the bullet list. The artifact you want opened — an epic, a demo PR — goes in the opening clause; sub-bullets are supporting evidence. Promoting it out of the list is what marks it as the thing to read.
- **Frame by what the reader can do**, not what you built. Not "X is now a reusable action instead of ~16k vendored lines" but "X is avail to try (add the `<label>` label to a PR) once these land on main" — include the activation step.
- **Link instead of retelling.** If the explanation already lives in a Slack thread, GitHub issue, or doc, link it and cut the recap: `See my update here for details and links: <permalink>`.
- **Hedge honestly and say why.** Name the state of the thing ("a very rough e2e prototype working (with lots of holes)") and the reason for the path taken over the alternative ("the CLI makes it very easy to get the contracts right and iterate quickly"). Confidence and reasoning, not just status.
- **State blockers in the first person, including human ones.** Not "waiting on >= 1.0.81" but "I need to wait for a release and permission to start." A person you're waiting on is a blocker; name it.
- **Keep concrete detail with a consequence.** "Filed [repo#123](url) — the docs don't explain log filtering during validation, which cost me time." Specific, first-person, names the cost. This register survives; abstraction and scene-setting don't.
- **Leave room for artifacts the user adds** — demo videos, Slack permalinks to their own earlier messages. Don't pad a theme to wall-to-wall PR bullets.

### PR bullet format

Nest PR bullets under the theme bullet they support. Use **four leading spaces** before nested PR bullets; two spaces can render inconsistently in Slack.

```
* One-sentence theme, ending in a colon:
    * :merged: [<title>](https://github.com/org/repo/pull/N)
    * :review: [<title>](https://github.com/org/repo/pull/N) -> optional inline commentary
```

- `:merged:` — PR authored by user, merged in window.
- `:review:` — PR authored by user, still open.
- Inline commentary after a PR bullet (e.g. `-> will try this out tomorrow, low priority.`) is encouraged when useful.
- Use markdown link syntax so Slack renders titles as clickable links.

**A PR that needs no narrative goes bare.** Put it as a top-level `:merged:`/`:review:` bullet near the end, with no theme sentence above it and no "Misc" header. Never manufacture a grouping to justify a link — if the only sentence you can write is "housekeeping — dependency PRs are automated now", drop the sentence and keep the links. Bare bullets can still carry inline commentary.

**When in doubt, cut the link.** A tight handoff has noticeably fewer PR links than the set of PRs you touched. Every link should be one the reader might open.

### What to drop

- **Personal-account PRs** (`tclem/*`). These are side projects and are excluded by default. Org-owned repos (`github/*` and any other orgs the user contributes to) are eligible — only the personal account is filtered.
- **Yesterday's already-merged work** that's no longer in flight. Focus on what's active *now*.
- **Dependabot / auto-generated / trivial chore PRs**, unless the user flags them.
- **PRs you only reviewed or approved.** GitHub's `commenter:` search qualifier includes approvals, so `gh-log`'s "commented on" bucket conflates real discussion with routine approvals — use it only as narrative hints, never as bullets. Verify with `gh pr view <url> --comments` before framing anything as "discussing."
- **Meta work about the user's own tooling or agent environment** — their Copilot setup, MCP bugs, skill maintenance. The team can't act on it. Include only when the user flags it.
- **Anything already said in-channel.** If Slack search shows the user already posted it where the handoff goes, don't restate it — link the thread or cut it. Slack is a cut-reason as well as a source.

## Output format

One fenced code block, starting with `Handoff:`. **Everything goes in this single block** — every work stream is just another theme bullet here. When posting late, say so in the label: `Handoff (from yesterday):`, `Handoff (covers Tue + Wed):`.

````
```
Handoff:
* <Meeting name>
* <Meeting name>
* <Notable conversation — one clause, with @handle>

* <On-call narrative if applicable — how the day went, what landed, what didn't, who helped>.

* <Theme 1, one sentence — the key artifact linked inline, not below>:
    * :merged: [<title>](https://github.com/org/repo/pull/N)
    * :review: [<title>](https://github.com/org/repo/pull/N)

* <Theme 2 — what the reader can now do, with the activation step>:
    * :review: [<title>](https://github.com/org/repo/pull/N) -> optional inline note

* :merged: [<PR that needs no narrative>](https://github.com/org/repo/pull/N)
* :review: [<another>](https://github.com/org/repo/pull/N) -> optional inline note
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
- Don't invent context. If a PR's purpose isn't clear from its title or session, ask or omit.

---
name: thinking-about
description: Use when the user wants to capture a thought into their tclem/notes inbox, or when running the daily rollup that re-themes the top-of-mind list.
user-invocable: true
---

# Thinking About

Two modes against the `tclem/notes` repo:

1. **Capture** — append a single thought to `thinking-about.md` at the repo root (the rolling raw inbox), tagged and anchored so the rollup can link back to it.
2. **Rollup** — re-theme `thinking-about.md`, regenerate `top-of-mind.md` at the repo root, and prune resolved/stale entries into `archive/YYYY/`.

This skill is the only thing that should write to `thinking-about.md` or `top-of-mind.md`. Don't edit those files manually from other skills.

## When to use

Capture mode — when the user supplies free text as a thought to save (e.g. `/thinking-about <text>`, "add to my thinking-about", "park this in my notes inbox").

Rollup mode — when a scheduled rollup workflow fires, or the user explicitly asks to "rollup", "re-theme", "regenerate top of mind", or "review the inbox".

If the invocation is ambiguous (no thought text and no explicit rollup intent), ask which mode before doing anything. Do **not** default to rollup, because rollup writes and prunes across multiple files.

## Repo setup

Work in the local checkout at `~/github/notes` when it exists; that's the canonical working copy. If it's missing or out of date:

```bash
if [ ! -d ~/github/notes/.git ]; then
  gh repo clone tclem/notes ~/github/notes
fi
cd ~/github/notes
git pull --ff-only origin main
```

All commits go directly to `main`. Push after each operation.

## Capture

### File shape

`thinking-about.md` is a single rolling Markdown file at the repo root:

```markdown
# Thinking about

Raw, append-only inbox of things on my mind. Captured by the `thinking-about`
skill (in `tclem/dotfiles`). The daily rollup at [`top-of-mind.md`](top-of-mind.md)
synthesizes themes and links back to specific entries by anchor.

Tags: #thinking-about #inbox

<a id="t-0042"></a>
- **2026-05-16 14:32** — short text of the thought.
  Optional follow-up lines indented two spaces.

<a id="t-0043"></a>
- **2026-05-16 17:05** — another thought.
```

Rules:

- Entries are append-only. Never edit or renumber an existing entry from Capture mode — only Rollup may move entries out.
- IDs are zero-padded monotonic `t-NNNN`, never reused. Pick the next ID by scanning the file (and `archive/**/*-thinking-about.md`) for the highest existing `t-NNNN` and incrementing.
- Timestamp is local time in `YYYY-MM-DD HH:MM`.
- The first line of an entry is the user's thought, lightly cleaned (typos and trailing punctuation) but **not paraphrased**. In-bounds: fix obvious misspellings, autocorrect artifacts, missing punctuation at end of sentence. Out of bounds: rewording for clarity, splitting run-on sentences, "fixing" nonstandard phrasing, expanding abbreviations, adding context the user didn't write. If you're tempted to "make it clearer", stop and append the entry verbatim.
- If the file does not exist yet, create it with the header block above and start IDs at `t-0001`.

### Capture steps

1. `cd ~/github/notes && git pull --ff-only origin main`.
2. Determine next ID.
3. Append the new entry block at the end of the file (preserve the trailing newline).
4. Stage, commit, push:

   ```bash
   git add thinking-about.md
   git commit -m "thinking-about: capture t-NNNN"
   git push
   ```

5. Report the ID and the captured text back to the user.

Commit messages stay terse — the diff is self-explanatory. No `Co-authored-by` trailer (this is a personal notebook, not collaborative authorship).

## Rollup

The rollup regenerates `top-of-mind.md` at the repo root and prunes the inbox. Run it daily via the workflow, or on demand.

### Inputs

- `thinking-about.md` at the repo root — current inbox.
- Previous `top-of-mind.md` at repo root — read it to preserve theme names and synthesis where they're still accurate. Do not blindly overwrite.
- `archive/YYYY/` — for ID collision avoidance and historical context.

### Judgments per entry

For each entry in the inbox, decide one of:

- **Active in theme.** Belongs in a current theme on top-of-mind. Leave in the inbox, reference from the theme.
- **Active unthemed.** Recent (last 7 days) and not yet thematic. Leave in the inbox; surface under "Unthemed recent".
- **Resolved.** Marked `(done)`, `[x]`, `~~strikethrough~~`, or the synthesis from previous rollups indicates resolution. Prune to archive.
- **Stale.** Older than 30 days, not referenced in any current theme, no user signal to keep. Prune to archive.

**When in doubt, leave it in the inbox.** Pruning is reversible (git history) but noisy. Err toward keeping entries visible until a clear signal arrives.

### top-of-mind.md shape

```markdown
# Top of mind

Rolled up YYYY-MM-DD from [`thinking-about.md`](thinking-about.md).
Each item links to its raw entry.

## Themes

### <Theme name>

One- to three-line synthesis of what's going on in this theme.

- [t-0012](thinking-about.md#t-0012) — short title or excerpt
- [t-0018](thinking-about.md#t-0018) — short title or excerpt

### <Another theme>

...

## Unthemed recent

Captured in the last 7 days, not yet part of a theme:

- [t-0044](thinking-about.md#t-0044) — short text
- [t-0045](thinking-about.md#t-0045) — short text

## Resolved this rollup

- [t-0005] — moved to `archive/2026/2026-05-16-thinking-about.md`; was about <X>.

## Stale this rollup

- [t-0009] — moved to `archive/2026/2026-05-16-thinking-about.md`; not revisited since 2026-04-08.
```

Rules:

- **Themes are durable.** If the previous `top-of-mind.md` already named a theme and it's still active, keep the same name and adjust membership. Only rename a theme when its current membership has shifted such that the old name actively misleads (e.g. theme was "Search latency" but every active entry is now about indexing throughput). Tightening, broadening, or aesthetic improvements are not reasons to rename.
- **Synthesis is short.** One to three lines per theme. The rollup is an index, not an essay.
- **Linkbacks only.** The top-of-mind file does not duplicate entry content; it links to the inbox or archive.
- **Section order is fixed.** Themes → Unthemed recent → Resolved this rollup → Stale this rollup. Drop empty sections.

### Archive on prune

When pruning (Resolved or Stale), move the entry **including its anchor** to a dated archive file:

```
archive/<YYYY>/<YYYY-MM-DD>-thinking-about.md
```

where `<YYYY-MM-DD>` is the day the rollup is running. Multiple prunes on the same day accumulate into the same archive file. Archive file shape:

```markdown
# Thinking about — pruned YYYY-MM-DD

Entries moved out of `thinking-about.md` by the daily rollup. Anchors
preserved so external links still resolve.

Tags: #thinking-about #archive

<a id="t-0005"></a>
- **2026-04-01 09:12** — original entry text (verbatim).
  Pruned: resolved (synthesis: ...).

<a id="t-0009"></a>
- **2026-04-08 15:40** — original entry text.
  Pruned: stale.
```

The pruning note (single line after the original content) records the reason. Original content is verbatim.

### Rollup steps

1. `cd ~/github/notes && git pull --ff-only origin main`.
2. Read inbox, previous top-of-mind, and any archive entries from the last 60 days for context.
3. Make per-entry judgments. **Print the judgment list and ask the user to confirm prunes** when run interactively. The daily workflow is non-interactive — in that case, only prune entries that match the explicit signals (`(done)`, `[x]`, `~~...~~`, or `> 60 days untouched with no theme membership`). Treat the 30-day threshold as advisory in non-interactive mode; default to keeping.
4. Cluster active entries into themes. Reuse previous theme names where they still fit.
5. Rewrite `top-of-mind.md` at the repo root.
6. For each prune: remove the entry block from `thinking-about.md`, append to today's archive file (create directory if needed) with the pruning reason.
7. Commit as a single rollup commit:

   ```bash
   git add top-of-mind.md thinking-about.md archive
   git commit -m "thinking-about: rollup YYYY-MM-DD (N themes, M pruned)"
   git push
   ```

8. Report a short summary: theme count, prune count, link to the commit.

## Common mistakes

- **Paraphrasing the user's thought in Capture.** Lightly clean typos only. Tim wrote it; keep his voice.
- **Reusing IDs.** Always scan the inbox *and* archives for the highest existing ID before assigning.
- **Editing existing entries in Capture mode.** Capture only appends.
- **Aggressive pruning in non-interactive mode.** The daily workflow should be conservative — keep entries unless they're explicitly resolved or extremely stale.
- **Churning theme names.** If yesterday's rollup named a theme "Search latency" and today's items still fit, don't rename it to "Performance" without reason.
- **Long syntheses.** The rollup is an index. One to three lines per theme.
- **Forgetting the linkback anchors when archiving.** Archived entries must keep their `<a id="t-NNNN"></a>` so external links continue to resolve.
- **Editing `top-of-mind.md` outside this skill.** It's generated; any manual edits are blown away on the next rollup.

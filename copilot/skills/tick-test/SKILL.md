---
name: tick-test
description: A safe demo automation that mirrors agent-merge's drive-to-done loop on the tick cycle. Use when this skill is selected as the workspace tick automation. Drives a scratch checklist to completion — one item per tick — then self-stops.
---

# Tick test

A **teaching/demo automation** for the scheduled tick cycle. It has the same
shape as `agent-merge` — define a goal, triage current state, do one unit of
work, end the turn, let the next tick re-run you, and call `stop_session_tick`
when done — but it operates only on a throwaway scratch file. No git, no PR, no
network, nothing destructive. The point is to make the *mechanism* visible.

Unlike `marco-polo` (call-and-response, nothing to do on a silent tick), this
skill exists *because* the tick fired and does real, observable, idempotent work
each time.

## Goal

Drive every item in the demo checklist at `TICK_TEST.md` (repo root) to `[x]`.
When all items are checked, the automation is done and stops itself.

## Done conditions

| Condition | How to check |
|-----------|--------------|
| Checklist exists | `TICK_TEST.md` is present at the repo root |
| All work complete | Every `- [ ]` line in `TICK_TEST.md` is now `- [x]` |

## Rules (the unsupervised-loop discipline)

- **The tick is the loop.** Do one unit of work, then **end the turn**. The next
  tick re-runs you. Never `sleep`, never poll, never block waiting.
- **Be idempotent.** Re-read `TICK_TEST.md` every tick to find the *next*
  unchecked item. Never rely on memory of a prior tick, and never redo an item
  that's already `[x]`. This proves state survives across fresh turns.
- **Append/check in place — never clobber.** Editing one line per tick and
  leaving the rest untouched is how this verifies the tick *queues behind*
  in-flight work instead of steering over it.
- **Stop explicitly** with `stop_session_tick` only at a terminal condition
  (all items done). Don't stop early just because one tick finished its unit.

## Workflow

### 1. Triage

Read `TICK_TEST.md`.

- **Missing?** This is the first tick. Create it with a header and a 3-item demo
  checklist, then treat item 1 as the next unit (continue to step 2):

  ```markdown
  # Tick test — demo checklist

  Each tick completes the next unchecked item. When all are checked, the
  automation stops itself.

  - [ ] step 1
  - [ ] step 2
  - [ ] step 3
  ```

- **Present?** Find the first `- [ ]` (unchecked) line. If there is none, every
  item is done → go to step 3 (stop).

### 2. Act — complete exactly one item

Change the first unchecked `- [ ]` to `- [x]` and append the completion time, e.g.:

```
- [x] step 1 — done at 2026-05-31T22:40:00Z
```

Touch only that one line. Then re-check: are any `- [ ]` lines left?

- **Yes** → summarize what you did ("Completed step 1; 2 remaining. Next tick
  will handle step 2.") and **END THE TURN**. Do **not** call
  `stop_session_tick` — you want the next tick to fire.
- **No** → continue to step 3.

### 3. Stop

All items are `[x]`. Append a final line `- ✅ tick test complete` to
`TICK_TEST.md`, summarize, and call the `stop_session_tick` tool so the
automation disables itself and the workspace's tick selection returns to Off.

## What this demonstrates

- **Cadence** — the loop fires (first tick immediately, then one per interval).
- **Queue, not steer** — items are checked off in order; in-flight work is never
  interrupted.
- **State across ticks** — each fresh turn recovers progress from `TICK_TEST.md`.
- **Self-stop** — `stop_session_tick` flips the UI selection back to Off.

## Cleanup

When you've seen the loop work, delete `TICK_TEST.md` — it's a throwaway.

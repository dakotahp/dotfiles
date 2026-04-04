# /start-day

Morning note primer. Creates today's daily note from the template, then fills in the `## Today's Priorities` and `## Morning Context` sections based on vault content. Fully non-interactive — makes all judgments autonomously, writes to the note, done.

## What it does

**Step 1 — Create today's note**
Runs `obsidian daily` to create the note from the template if it doesn't exist, or opens it if it does.

**Step 2 — Load context**
Reads four sources in parallel before doing any analysis:
- `2_Areas/Life Domains.md` — strategic priorities and seasonal context
- `2_Areas/Personal Knowledge Management/Avoidance Radar.md` — deferred items with ages
- Most recent archived daily note — extracts unchecked action items from its `## Distillation`
- `1_Projects/` modification timestamps — staleness signal for project nudges

**Step 3 — Build Today's Priorities**
Assembles checkboxes in priority order, capped at 6 items:

1. **Rolled-over todos** — unchecked action items from yesterday's Distillation. Always included, never dropped.
2. **Avoidance Radar items** — escalated by age since first noted:
   - < 3 days: not surfaced yet
   - 3–6 days: plain `- [ ] Item` at the bottom
   - 7–13 days: `- [ ] Item *(7 days)*` mid-list
   - 14–20 days: `- [ ] Item *(14 days — still waiting)*` near top
   - 21+ days: `- [ ] Item *(21 days — decide or drop it)*` at the top
3. **Domain nudge** — one soft prompt if a seasonally active life domain has zero representation in todos or Radar items: `- [ ] Yard/garden: anything to move forward today?`
4. **Stale project flag** — one line if any project Index hasn't been touched in 30+ days

**Step 4 — Build Morning Context**
Two lines, both brief:
- **Always:** one sentence from Life Domains `## Current Context` — the most time-sensitive seasonal point
- **Conditionally:** if any Radar item is 14+ days old: `Overdue: [item] (N days), ...` — direct, no softening

**Step 5 — Write to the note**
Uses the Edit tool to fill the empty section patterns from the template. Idempotent — if sections already have content, the patterns don't match and nothing is overwritten.

## Files this skill touches

| File | What happens |
|------|-------------|
| `0_Inbox/YYYY-MM-DD.md` | Created from template (if new), priorities and context filled in |

## Dependencies

Reads from (must exist):
- `2_Areas/Life Domains.md` — seasonal context and domain cadence
- `2_Areas/Personal Knowledge Management/Avoidance Radar.md` — deferred items

## Part of the skill trio

This skill is part of a three-skill daily/weekly workflow:

- **`/start-day`** ← you are here — primes the note each morning
- **`/end-day`** — classifies, routes, distills, archives
- **`/end-week`** — weekly cofounder session; surveys the week, picks highest-leverage project, does real work

## Invocation

```
/start-day
```

Run first thing in the morning. Takes under a minute. No questions asked.

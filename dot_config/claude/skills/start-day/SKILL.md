---
name: start-day
description: Use when starting the day to prime the daily note with priorities and morning context. Non-interactive — runs silently and writes to the note.
allowed-tools: Bash, Read, Edit
---

Primes today's daily note with pre-filled Today's Priorities and Morning Context sections. Non-interactive — makes all judgments autonomously, writes to the note, done. No questions asked.

Vault: ObsidianPersonal. All obsidian commands use `vault=ObsidianPersonal` immediately after the subcommand.

---

## Step 1 — Create today's note

```bash
obsidian daily vault=ObsidianPersonal
```

Creates today's note from the template if it doesn't exist, opens it if it does. Note the date from the returned path (e.g. `0_Inbox/2026-04-04.md` → today is `2026-04-04`).

---

## Step 2 — Load context

Run all reads before any analysis:

```bash
# Life Domains manifest
obsidian read vault=ObsidianPersonal path="2_Areas/Life Domains.md"

# Avoidance Radar
obsidian read vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md"

# List archived daily notes to find most recent
obsidian files vault=ObsidianPersonal folder="4_Archive/Daily Notes"

# Project index files — get modification timestamps for staleness check
find /home/neropol/Syncthing/ObsidianPersonal/1_Projects -maxdepth 2 -name "Index.md" -printf "%T@ %p\n" | sort -rn
```

After listing archived notes, read the most recent one (highest date by filename):

```bash
obsidian read vault=ObsidianPersonal path="4_Archive/Daily Notes/YYYY-MM/YYYY-MM-DD.md"
```

---

## Step 3 — Analyse and build content

Work through each source in order. Build two strings: PRIORITIES_CONTENT and CONTEXT_CONTENT.

### Rolled-over todos

Find `## Distillation` in the most recent archived note. Under `**Action items:**`, extract every line matching `- [ ]` (unchecked only — skip `- [x]`). Include these verbatim as the first items in PRIORITIES_CONTENT.

### Avoidance Radar items

For each `- [ ]` line in the Radar, extract the item text (before ` —`) and the date after `first noted:`. Calculate days elapsed from today.

Escalation rules:

| Age | Action | Format |
|-----|--------|--------|
| < 3 days | Skip | — |
| 3–6 days | Bottom of list | `- [ ] Item` |
| 7–13 days | Mid-list | `- [ ] Item *(N days)*` |
| 14–20 days | Near top | `- [ ] Item *(N days — still waiting)*` |
| 21+ days | Top of list | `- [ ] Item *(N days — decide or drop it)*` |

Sort so oldest items appear highest. Append after rolled-over todos, in age order.

### Domain-aware nudge

Read Life Domains `## Current Context` and `## Life Domains`. Identify any domain marked as seasonally active or high-priority. If none of that domain's concerns appear in the rolled-over todos or surfaced Radar items, add one soft prompt at the bottom of PRIORITIES_CONTENT:

`- [ ] [Domain name]: anything to move forward today?`

Maximum one nudge. Skip entirely if active domains are already represented.

### Stale project flag

From the `find` output, convert each timestamp to a date and calculate days since last modification. If any `Index.md` is 30+ days old, pick the one with the most recent modification (least stale) and add one line:

`- [ ] [Project name]: no activity in N days — worth a push?`

Skip if a rolled-over todo already references that project. Skip if everything is under 30 days.

### Cap

If PRIORITIES_CONTENT has more than 6 items, remove from the bottom: drop the youngest Radar items first, then the domain nudge, then the stale flag. Never drop rolled-over todos.

### Morning Context

- **Line 1 (always):** One sentence from Life Domains `## Current Context`. The single most time-sensitive or seasonally relevant point only.
- **Line 2 (conditional):** Only if any Radar item is 14+ days old: `Overdue: [item name] (N days), [item name] (N days).` List all items 14+ days. Omit this line entirely if nothing qualifies.

---

## Step 4 — Write to today's note

Get the exact path of today's note:

```bash
obsidian daily:path vault=ObsidianPersonal
```

The full filesystem path is `/home/neropol/Syncthing/ObsidianPersonal/` + the returned vault-relative path.

The note has empty `## Today's Priorities` and `## Morning Context` sections from the template. Use the Edit tool to fill each one by replacing the empty-section pattern.

**Fill Today's Priorities** — find this exact string in the file:

```
## Today's Priorities

## Morning Context
```

Replace with:

```
## Today's Priorities

[PRIORITIES_CONTENT]

## Morning Context
```

**Fill Morning Context** — find this exact string in the file:

```
## Morning Context

## Brain Dump
```

Replace with:

```
## Morning Context

[CONTEXT_CONTENT]

## Brain Dump
```

Make both edits sequentially. Do not modify any other part of the note. If either pattern is not found (sections already have content — note was pre-edited), skip that edit silently.

---

## Done

No output needed. The note is ready.

---
name: start-day
description: Use when starting the day to set up today's daily note and process any prior unprocessed notes.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, mcp__claude_ai_Google_Calendar__list_events
---

Morning startup for the personal Obsidian vault. Runs in two phases: first closes out any unprocessed daily notes from prior days (routing content to its destination and archiving), then primes today's note with rolled-over todos, Avoidance Radar items, and context. Non-interactive except for ambiguous `2_Areas` folder matches.

Vault: ObsidianPersonal. All obsidian commands use `vault=ObsidianPersonal` immediately after the subcommand.

Key rules:
- Vault parameter comes immediately after the subcommand: `obsidian <subcommand> vault=ObsidianPersonal [options]`
- Use `path=` for exact vault-relative paths; `file=` for wikilink-style name resolution
- Never run `obsidian --help` — it hangs and never exits

---

## Phase 1 — Close out unprocessed notes

### Step 1a — Find unprocessed daily notes

Get today's daily note path to learn the inbox folder:

```bash
obsidian daily:path vault=ObsidianPersonal
```

This returns a vault-relative path like `0_Inbox/2026-04-11.md`. Extract the containing folder (`0_Inbox/`) and today's date.

List everything in that folder:

```bash
obsidian files vault=ObsidianPersonal folder="0_Inbox"
```

Filter to files matching the `YYYY-MM-DD.md` pattern **where the date is before today**. Sort ascending (oldest first). These are unprocessed prior notes.

If none exist, skip to Phase 2.

### Step 1b — Process each prior note (oldest first, no pausing between notes)

Repeat Steps 1b-i through 1b-v for every unprocessed prior note. The only exception to no-pausing is an ambiguous `2_Areas` folder match (see Step 1b-iii).

**Track for each note:** count of todos, avoidance items, idea stubs, learnings filed. Carry the extracted action items forward in memory — they feed directly into Phase 2.

#### Step 1b-i — Read, resolve wikilinks, and classify

```bash
obsidian read vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md"
```

If the note is empty or contains only a template skeleton with no substantive content, skip to Step 1b-v (archiving).

**Wikilink context override** — extract all `[[...]]` references from the note text. For each link name, search `1_Projects/` and `2_Areas/` in parallel:

```bash
obsidian search vault=ObsidianPersonal folder="1_Projects" query="<link name>" format=json
obsidian search vault=ObsidianPersonal folder="2_Areas" query="<link name>" format=json
```

If a match is found in either folder and is not already in the project context map, read the matched file and any sibling files with `agent-context: project` (or `agent-context: area` if under `2_Areas/`) in their frontmatter, then add them to the map. This surfaces projects and areas referenced intentionally but outside the 14-day auto-load window.

**Classify** every meaningful item into one of five types (most specific match wins):

| Type | What it looks like |
|------|--------------------|
| **Hard todo** | An explicit next action: "I need to", "call X", "book Y", "follow up on Z" |
| **Avoidance item** | Something being put off — reappears across notes, reluctant tone |
| **Reflection** | Mood, mental state, day observations — not actionable |
| **Learning** | A fact, concept, or insight acquired from reading, a call, or experience |
| **Idea fragment** | A half-formed thought with no clear next step yet |

Items under `## Today's Priorities` are hard todos by default (unchecked only — skip `- [x]`).

**Project attribution** — for each hard todo, fuzzy-match its text against project names in the project context map. A direct name mention, a wikilink to the project, or a domain clearly owned by one project all count. Tag each todo internally with its matched project, or mark it "unattributed" if no match.

#### Step 1b-ii — Create idea stubs in 0_Inbox

For each **idea fragment**:

```bash
obsidian create vault=ObsidianPersonal path="0_Inbox/Idea - <Short Title>.md" content="---\ntags:\n  - idea\n  - stub\nsource: \"[[YYYY-MM-DD]]\"\n---\n\n<raw thought, verbatim or lightly cleaned>" silent
```

Keep `<Short Title>` to 4–6 words. Don't expand or elaborate.

#### Step 1b-iii — Append avoidance items to Avoidance Radar

For each **avoidance item**, first read the Radar and fuzzy-match to avoid duplicates:

```bash
obsidian read vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md"
```

If not already present, append:

```bash
obsidian append vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md" content="\n- [ ] <item> — *first noted: YYYY-MM-DD*"
```

If the file doesn't exist, create it first:

```bash
obsidian create vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md" content="---\nagent-context: vault\n---\n\nThings that keep coming up but keep getting deferred. Reviewed weekly.\n" silent
```

#### Step 1b-iv — File learnings into 2_Areas

For each **learning**, list `2_Areas/` subfolders and match semantically:

```bash
obsidian files vault=ObsidianPersonal folder="2_Areas"
```

**Clear match:** proceed without asking. **No match:** suggest top 2 candidates or offer to create a new folder — this is the **only** time to pause. Once answered, continue.

```bash
# Append to existing note
obsidian append vault=ObsidianPersonal file="<Note Name>" content="\n---\n\n<learning content>\n\nSource: [[YYYY-MM-DD]]"

# Or create a new note
obsidian create vault=ObsidianPersonal path="2_Areas/<Subfolder>/<Title>.md" content="---\ntags:\n  - <tag>\n---\n\n<learning content>\n\nSource: [[YYYY-MM-DD]]" silent
```

#### Step 1b-v — Write Distillation, navigation footer, archive

**Distillation** — append before archiving:

```bash
obsidian append vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md" content="## Distillation\n\n**Day in brief:** <1–2 sentence synthesis of the day's tone, main themes, and energy — drawn from project context where applicable, not just the surface text>\n\n**Action items:**\n\n*[[Project Name]]:*\n- [ ] <item> *(<brief context informed by project state>)*\n\n*Unattributed:*\n- [ ] <item> *(<brief context>)*\n\n**Avoiding** *(added to Avoidance Radar):*\n- <item, or omit block if none>\n\n**Ideas stubbed to Inbox:**\n- [[Idea - <title>]]\n\n**Filed to 2_Areas:**\n- [[<Area Note>]] ← <learning summary>"
```

Omit any subsection with nothing to show. For **Action items**: group todos under their attributed project as a subheading. If all todos are unattributed, skip the grouping and list flat. If only one project is represented, skip the project subheading and annotate each item inline with `*(→ [[Project Name]])*`. Omit the *Unattributed* heading if everything is attributed.

**Navigation footer** — the note may already have a `← [[PREV-DATE]]` line (added by Phase 2 when today's note was primed). If so, replace it with the full bidirectional footer using a direct file edit on the full filesystem path (`$VAULT_PATH/0_Inbox/YYYY-MM-DD.md`):

```bash
sed -i "s|← \[\[PREV-DATE\]\]|← [[PREV-DATE]] | → [[NEXT-DATE]]|" "$VAULT_PATH/0_Inbox/YYYY-MM-DD.md"
```

If no footer line exists yet (note was never primed by Phase 2), append instead:

```bash
obsidian append vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md" content="\n\n---\n← [[PREV-DATE]] | → [[NEXT-DATE]]"
```

- `PREV-DATE`: calendar day before this note's date
- `NEXT-DATE`: calendar day after this note's date

**Archive:**

```bash
obsidian move vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md" to="4_Archive/Daily Notes/YYYY-MM/YYYY-MM-DD.md"
```

---

## Phase 2 — Prime today's note

### Step 2a — Create today's note

```bash
obsidian daily vault=ObsidianPersonal
```

Creates today's note from the template if it doesn't exist.

### Step 2b — Load context

Run all reads in parallel before any analysis:

**Work calendar** — fetch today's events via MCP (not bash):

```
mcp__claude_ai_Google_Calendar__list_events(
  calendarId="dakotah.pena@apartmentiq.io",
  startTime="<today>T00:00:00",
  endTime="<today>T23:59:59",
  orderBy="startTime",
  timeZone="America/Los_Angeles"
)
```

Store results as **CALENDAR_EVENTS** — a list of `{summary, start, end}` objects. If the call fails or returns empty, store an empty list and continue silently.

```bash
# Daily quote source
obsidian read vault=ObsidianPersonal path="2_Areas/Quotes.md"

# Inspiration file index
obsidian search vault=ObsidianPersonal query="tag:#inspiration" format=json

# Life Domains manifest
obsidian read vault=ObsidianPersonal path="2_Areas/Life Domains.md"

# Avoidance Radar (freshly updated by Phase 1)
obsidian read vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md"

# Project Index modification times for staleness check (vault API — portable, no hardcoded path)
obsidian eval vault=ObsidianPersonal code="JSON.stringify(app.vault.getFiles().filter(f => f.path.startsWith('1_Projects/') && f.name === 'Index.md').map(f => ({path: f.path, mtime: f.stat.mtime})).sort((a,b) => a.mtime - b.mtime))"

# Vault-scope agent context — global personal frame, loaded every session
obsidian vault=ObsidianPersonal search query="[agent-context:vault]" format=json
# Read each returned path. These provide who-I-am, life-domain, and long-running-goals context.

# Most recent weekly note — strategic frame for the current ISO week
# Stale-week guard: only use if the filename matches today's ISO week (date +%Y-%V → e.g. "2026-17").
# If absent (no end-week run yet this week, or first week of vault), skip silently.
CURRENT_WEEK=$(date +%Y-%V)
obsidian files vault=ObsidianPersonal folder="4_Archive/Weekly Notes"
# From the returned list, find the file matching $CURRENT_WEEK.md. If found:
obsidian read vault=ObsidianPersonal path="4_Archive/Weekly Notes/$CURRENT_WEEK.md"
# Used as AMBIENT CONTEXT ONLY — do not replicate any of its content into today's daily note.
# It informs internal calibration: which rolled-over todos feel weightier (project matched `## Projects Focused`),
# which domain nudges to favor (open `## Decisions Needed` items), whether to flag a stale project
# (already covered by `## Archive Candidates`). No new visible lines in the daily note from this read.

# Project-scope agent-context files in 1_Projects modified within 14 days
# obsidian CLI has no date filter — find used here to overcome that limitation
# obsidian eval prefixes output with "=> "; strip it before using as a path
VAULT_PATH=$(obsidian eval vault=ObsidianPersonal code="app.vault.adapter.basePath" | sed 's/^=> //')
find "$VAULT_PATH/1_Projects" -name "*.md" -mtime -14 | xargs grep -l "^agent-context: project" 2>/dev/null
```

Read each file from the last command and build the **project context map**: project name (from path or frontmatter title) → key details (goal, current status, any constraints or blockers noted). This map is shared across Phase 1 and Phase 2.

**Rolled-over todos:**
- **If Phase 1 processed any notes:** use the action items already in memory from those Distillations — skip the archive re-read.
- **If Phase 1 had nothing to process:** list archived notes and read the most recent one to extract rolled-over todos:

```bash
obsidian files vault=ObsidianPersonal folder="4_Archive/Daily Notes"
obsidian read vault=ObsidianPersonal path="4_Archive/Daily Notes/YYYY-MM/YYYY-MM-DD.md"
```

Find `## Distillation` → `**Action items:**`, extract every `- [ ]` line verbatim.

**Recurring todo escalation** — before building priorities, check for todos stuck across 3+ days. Read the two archived Distillations immediately preceding the source note and extract their unchecked `- [ ]` action items. Any todo text that fuzzy-matches a rolled-over todo in both prior notes has been deferred for 3+ consecutive days — escalate it: append to Avoidance Radar (Step 1b-iii format, `first noted:` = today's date) and remove it from rolled-over todos. Skip this check if fewer than 2 prior archived Distillations exist.

### Step 2b-ii — Pick today's quote and inspiration

**Quote** — from `Quotes.md`, extract every line beginning with `- `. Strip the leading `- `. Use today's date as a seed: take the day-of-year (1–366), mod by the number of quotes, and select that line. Same quote all day if the skill runs twice.

Store as **QUOTE_CONTENT** — the raw line text including attribution and any `[[wikilink]]`.

**Inspiration** — from the `#inspiration` search results, apply the same day-of-year mod against the list to pick one file deterministically.

Read just the first non-frontmatter, non-heading line of that file (skip `---` blocks and lines starting with `#`). This is the teaser sentence.

Store as **INSPIRATION_PATH** (vault-relative path) and **INSPIRATION_TEASER** (the first prose line).

### Step 2c — Build PRIORITIES_CONTENT and CONTEXT_CONTENT

**Rolled-over todos** — first items in PRIORITIES_CONTENT, verbatim from Distillation.

**Avoidance Radar items** — for each `- [ ]` line, extract item text and `first noted:` date. Calculate days elapsed from today.

| Age | Action | Format |
|-----|--------|--------|
| < 3 days | Skip | — |
| 3–6 days | Bottom of list | `- [ ] Item` |
| 7–13 days | Mid-list | `- [ ] Item *(N days)*` |
| 14–20 days | Near top | `- [ ] Item *(N days — still waiting)*` |
| 21+ days | Top of list | `- [ ] Item *(N days — decide or drop it)*` |

Sort oldest first. Append after rolled-over todos.

**Domain-aware nudge** — from Life Domains `## Current Context` and `## Life Domains`, identify any seasonally active or high-priority domain. If none of its concerns appear in rolled-over todos or surfaced Radar items, add one soft prompt at the bottom:

`- [ ] [Domain name]: anything to move forward today?`

Maximum one nudge. Skip if active domains are already represented.

**Stale project flag** — from the `find` output, if any `Index.md` is 30+ days old, pick the least stale one and add:

`- [ ] [[Project name]]: no activity in N days — worth a push?`

Skip if a rolled-over todo already references that project. Skip if everything is under 30 days.

**Cap** — if PRIORITIES_CONTENT exceeds 6 items, remove from the bottom: youngest Radar items first, then domain nudge, then stale flag. Never drop rolled-over todos.

**CONTEXT_CONTENT:**
- **Line 1 (always):** One sentence from Life Domains `## Current Context` — the single most time-sensitive or seasonally relevant point.
- **Line 2 (conditional):** Only if any Radar item is 14+ days old: `Overdue: [item name] (N days), [item name] (N days).` Omit entirely if nothing qualifies.
- **Line 3 (conditional):** Only if CALENDAR_EVENTS is non-empty: `**Meetings:** HH:MM Event title, HH:MM Event title` — list each event's start time (12-hour, no seconds) and summary, comma-separated. Omit entirely if no events.

### Step 2d — Write to today's note

```bash
obsidian daily:path vault=ObsidianPersonal
```

Full filesystem path: `$VAULT_PATH/` + returned path (reuse the `VAULT_PATH` variable from Step 2b, already stripped of the `=>` prefix).

**Fill daily spark** — the template includes the callout scaffold with placeholder comments. Replace each placeholder:

- Find `<!-- quote -->` → replace with `[QUOTE_CONTENT]`
- Find `<!-- inspiration -->` → replace with `[[INSPIRATION_FILENAME]] — [INSPIRATION_TEASER]`

`INSPIRATION_FILENAME` is the bare note name (no path, no `.md`) for the wikilink. The `*italics*` wrapper is already in the template around the quote placeholder. If either placeholder is not found (skill already ran today), skip that replacement silently.

**Fill Today's Priorities** — find the exact placeholder and replace it:

- Find `<!-- priorities -->` → replace with `[PRIORITIES_CONTENT]`

**Fill Morning Context** — find the exact placeholder and replace it:

- Find `<!-- context -->` → replace with `[CONTEXT_CONTENT]`

Make both edits sequentially. If either placeholder is not found (skill already ran today), skip that edit silently.

**Append yesterday's navigation link** — calculate yesterday's date (today minus 1 day, formatted `YYYY-MM-DD`), then append to today's note:

```bash
obsidian append vault=ObsidianPersonal path="<TODAY_VAULT_PATH>" content="\n\n---\n← [[YESTERDAY-DATE]]"
```

If the note already ends with a nav footer line (starts with `←`), skip silently — the skill already ran today.

---

## Phase 3 — Summary

If Phase 1 processed any notes, show the processing table:

| Date | Todos | Avoidance | Idea stubs | Learnings filed | Archived |
|------|-------|-----------|------------|-----------------|---------|
| 2026-04-10 | 2 | — | — | — | ✓ |

One row per note. Show `—` for columns with nothing found. If a note was empty and skipped processing, note that in the row.

If Phase 1 had nothing to process, no summary needed — the note is ready silently.

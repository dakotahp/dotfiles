---
name: end-day
description: Use when the user wants to close out their day, process their daily note(s), or invokes /end-day. Handles today's note and any missed prior daily notes not yet archived (e.g., after vacation). Accepts an optional date argument to process a single specific day.
argument-hint: "[YYYY-MM-DD]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

End-of-day routine for the personal Obsidian vault: reads unprocessed daily notes, extracts action items, files learnings into `2_Areas/`, adds navigation links between consecutive notes, and archives each note.

The personal vault uses a PARA structure: `0_Inbox/`, `1_Projects/`, `2_Areas/`, `3_Resources/`, `4_Archive/`. Daily notes archive to `4_Archive/Daily Notes/YYYY-MM/`.

All vault interaction uses the `obsidian` CLI. Key rules:
- Vault parameter comes immediately after the subcommand: `obsidian <subcommand> vault=ObsidianPersonal [options]`
- Use `path=` for exact vault-relative paths; `file=` for wikilink-style name resolution
- Never run `obsidian --help` — it hangs and never exits

---

## Step 1 — Find unprocessed daily notes

Get the path of today's daily note to learn the daily notes folder:

```bash
obsidian daily:path vault=ObsidianPersonal
```

This returns a vault-relative path like `0_Inbox/2026-04-03.md`. Extract the containing folder (e.g., `0_Inbox/`).

List everything in that folder:

```bash
obsidian files vault=ObsidianPersonal folder="Daily Notes"
```

Any note still in this folder is unprocessed — processed notes get moved to the archive. Sort the list by filename ascending (oldest date first).

**If `$ARGUMENTS` is a date (e.g., `2026-04-01`):** filter the list to only that one note. If that note is not present in the folder, tell the user it was either already processed or doesn't exist, and stop.

**If `$ARGUMENTS` is empty:** process all notes in the folder in order.

If the resulting list is empty, tell the user there's nothing to process and stop.

---

## Step 2 — Process each note (oldest first, no pausing between notes)

Repeat Steps 2a–2d for every unprocessed note. Do **not** pause between notes for confirmation — work through all of them and present a summary at the end. The only exception is an ambiguous `2_Areas` folder match (see Step 2c).

### Step 2a — Read and parse the note

```bash
obsidian read vault=ObsidianPersonal path="Daily Notes/YYYY-MM-DD.md"
```

Parse the content for two categories:

**Brain dump / action items** — free-form prose, scattered thoughts, and anything implying a next step. Look for phrases like "I should", "need to", "follow up", "TODO", "look into", or tasks embedded in narrative. Also collate recurring themes — if a topic appears multiple times, surface it as something to act on.

**Learnings** — facts, concepts, insights from reading or experience, things researched, skills practiced. Anything that sounds like acquired knowledge worth keeping for future reference.

If the note is empty or contains only a template skeleton with no substantive content, skip Steps 2b and 2c and go directly to archiving (Step 2d).

### Step 2b — Append EOD Action Items section

From the brain dump parsing, collate all action items (explicit and implied) into a checklist. Append an `## EOD Action Items` section:

```bash
obsidian append vault=ObsidianPersonal path="Daily Notes/YYYY-MM-DD.md" content="## EOD Action Items\n\n- [ ] Action item one\n- [ ] Action item two"
```

If no clear action items exist, skip this step — don't add an empty section.

### Step 2c — File learnings into 2_Areas

For each distinct learning or insight, identify the best matching subfolder in `2_Areas/`:

```bash
obsidian files vault=ObsidianPersonal folder="2_Areas"
```

Match semantically, not literally — a learning about "morning routines" might fit `Health/` or `Habits/`. Use judgment.

**Clear match:** proceed without asking.

**No match:** suggest the top 2 candidates or offer to create a new folder. This is the **only** time to pause. Once answered, continue without further interruption.

For each learning, either append to an existing thematically related note or create a new one. Always include a backlink to the source daily note:

```bash
# Append to existing note
obsidian append vault=ObsidianPersonal file="<Note Name>" content="\n---\n\n<learning content>\n\nSource: [[YYYY-MM-DD]]"

# Create a new note
obsidian create vault=ObsidianPersonal path="2_Areas/<Subfolder>/<Title>.md" content="---\ntags:\n  - tag\n---\n\n<learning content>\n\nSource: [[YYYY-MM-DD]]" silent
```

Use `create` — `write` does not exist as a command.

### Step 2d — Add navigation links, then archive

**Navigation links** connect consecutive notes so you can page forward and backward between them.

Before moving this note, append a navigation footer to it with a backward link to the previous day:

```bash
obsidian append vault=ObsidianPersonal path="Daily Notes/YYYY-MM-DD.md" content="\n\n---\n← [[PREV-DATE]] | → [[NEXT-DATE]]"
```

- `PREV-DATE`: the calendar day before this note's date (regardless of whether it was processed this run — the link is useful even if that note was processed earlier)
- `NEXT-DATE`: leave as a placeholder wikilink — it won't resolve yet, but Obsidian will make it clickable once that note exists

After appending the footer, move the note to the archive:

```bash
obsidian move vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md" to="4_Archive/Daily Notes/YYYY-MM/YYYY-MM-DD.md"
```

Use `path=` with the full source path — do not use `file=` with `path=` together, that form errors. If the destination subfolder doesn't exist yet, the CLI creates it automatically.

**Back-fill the forward link on the previous note.** Now that this note is archived at a known path, update the predecessor's navigation footer. Look up the predecessor's archive location (`4_Archive/Daily Notes/PREV-YYYY-MM/PREV-DATE.md`) and replace its `NEXT-DATE` placeholder with the actual date of the note just archived:

```bash
obsidian append vault=ObsidianPersonal path="4_Archive/Daily Notes/PREV-YYYY-MM/PREV-DATE.md" content="\n\n---\n← [[PREV-PREV-DATE]] | → [[YYYY-MM-DD]]"
```

If the predecessor note doesn't exist in the archive (it predates any processing), skip the back-fill — don't create orphaned notes.

---

## Step 3 — Final summary

After all notes are processed, show a table:

| Date | Action items added | Learnings filed | Archived |
|------|--------------------|-----------------|---------|
| 2026-04-03 | 4 | 2 | ✓ |

One row per note. If a note was empty and skipped steps 2b/2c, show `—` in those columns.

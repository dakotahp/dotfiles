---
name: end-day
description: Use when the user wants to close out their day, process their daily note(s), or invokes /end-day. Handles today's note and any missed prior daily notes not yet archived (e.g., after vacation). Accepts an optional date argument to process a single specific day.
argument-hint: "[YYYY-MM-DD]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

End-of-day routine for the personal Obsidian vault: classifies daily note content into distinct types, routes each type to the right destination, writes a structured distillation, and archives the note.

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
obsidian files vault=ObsidianPersonal folder="0_Inbox"
```

Any note still in this folder is unprocessed — processed notes get moved to the archive. Filter to files matching the `YYYY-MM-DD.md` pattern. Sort ascending (oldest first).

**If `$ARGUMENTS` is a date (e.g., `2026-04-01`):** filter the list to only that one note. If not present, tell the user it was already processed or doesn't exist, and stop.

**If `$ARGUMENTS` is empty:** process all matching notes in order.

If the resulting list is empty, tell the user there's nothing to process and stop.

---

## Step 2 — Process each note (oldest first, no pausing between notes)

Repeat Steps 2a–2e for every unprocessed note. Do **not** pause between notes — work through all and present a summary at the end. The only exception is an ambiguous `2_Areas` folder match (see Step 2c).

### Step 2a — Read and classify the note

```bash
obsidian read vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md"
```

If the note is empty or contains only a template skeleton with no substantive content, skip to Step 2e (archiving).

Otherwise, classify every meaningful item in the note into one of these five types. A single captured thought can only belong to one type — use the most specific match:

| Type | What it looks like |
|------|--------------------|
| **Hard todo** | An explicit next action: "I need to", "call X", "book Y", "follow up on Z" |
| **Avoidance item** | Something the user *should* do but has been putting off, often reappears across notes, may have a guilty or reluctant tone |
| **Reflection** | Mood, mental state, observations about the day itself — not actionable |
| **Learning** | A fact, concept, or insight acquired from reading, a call, or experience — has a subject domain |
| **Idea fragment** | A half-formed thought, nascent concept, or "dust cloud" that hasn't crystallized into action — no clear next step yet |

Items under `## Today's Priorities` and `## EOD Action Items` (if already present from a partial run) are hard todos by default.

### Step 2b — Create idea stubs in 0_Inbox

For each item classified as an **idea fragment**, create a minimal stub note:

```bash
obsidian create vault=ObsidianPersonal path="0_Inbox/Idea - <Short Title>.md" content="---\ntags:\n  - idea\n  - stub\nsource: \"[[YYYY-MM-DD]]\"\n---\n\n<raw thought, verbatim or lightly cleaned>" silent
```

Keep `<Short Title>` to 4–6 words. These stubs are for later cultivation — don't expand or elaborate now.

### Step 2c — Append avoidance items to Avoidance Radar

For each **avoidance item**, append to `2_Areas/Personal Knowledge Management/Avoidance Radar.md`:

```bash
obsidian append vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md" content="\n- [ ] <item> — *first noted: YYYY-MM-DD*"
```

If the file doesn't exist, create it first:

```bash
obsidian create vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md" content="---\ntags:\n  - agent-context\n---\n\nThings that keep coming up but keep getting deferred. Reviewed weekly.\n" silent
```

Before appending, read the current Radar and check if the item is already present (fuzzy match on the core text). If it is, skip the duplicate — don't add it again.

### Step 2d — File learnings into 2_Areas

For each **learning**, identify the best matching subfolder in `2_Areas/`:

```bash
obsidian files vault=ObsidianPersonal folder="2_Areas"
```

Match semantically — a learning about "morning routines" might fit `Health & Fitness/` or `Personal Knowledge Management/`. Use judgment.

**Clear match:** proceed without asking.

**No match:** suggest the top 2 candidates or offer to create a new folder. This is the **only** time to pause and ask. Once answered, continue without further interruption.

Append to an existing thematically related note or create a new one. Always include a source backlink:

```bash
# Append to existing note
obsidian append vault=ObsidianPersonal file="<Note Name>" content="\n---\n\n<learning content>\n\nSource: [[YYYY-MM-DD]]"

# Create a new note
obsidian create vault=ObsidianPersonal path="2_Areas/<Subfolder>/<Title>.md" content="---\ntags:\n  - <tag>\n---\n\n<learning content>\n\nSource: [[YYYY-MM-DD]]" silent
```

### Step 2e — Write Distillation section, add navigation links, then archive

**Write the Distillation section** to the daily note. This replaces the old `## EOD Action Items` approach — write it as a single append before archiving:

```bash
obsidian append vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md" content="## Distillation\n\n**Day in brief:** <1–2 sentence synthesis of the day's tone, main themes, and energy if apparent — synthesized from mood language and recurring topics in the brain dump>\n\n**Action items:**\n- [ ] <item> *(<brief context: why it matters or what triggered it>)*\n\n**Avoiding** *(added to Avoidance Radar):*\n- <item, or 'none'>\n\n**Ideas stubbed to Inbox:**\n- [[Idea - <title>]]\n\n**Filed to 2_Areas:**\n- [[<Area Note>]] ← <learning summary>"
```

Omit any subsection that has nothing to show (e.g., if there were no avoidance items, omit that block entirely).

**Navigation footer** — append after the Distillation:

```bash
obsidian append vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md" content="\n\n---\n← [[PREV-DATE]] | → [[NEXT-DATE]]"
```

- `PREV-DATE`: calendar day before this note's date
- `NEXT-DATE`: placeholder — will resolve once that note is processed

**Archive the note:**

```bash
obsidian move vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md" to="4_Archive/Daily Notes/YYYY-MM/YYYY-MM-DD.md"
```

Use `path=` with the full source path. The CLI creates the destination subfolder automatically if needed.

**Back-fill the forward link on the previous note.** Update the predecessor's navigation footer now that this note is archived at a known path:

```bash
obsidian append vault=ObsidianPersonal path="4_Archive/Daily Notes/PREV-YYYY-MM/PREV-DATE.md" content="\n\n---\n← [[PREV-PREV-DATE]] | → [[YYYY-MM-DD]]"
```

If the predecessor doesn't exist in the archive, skip the back-fill.

---

## Step 3 — Final summary

After all notes are processed, show a table:

| Date | Todos | Avoidance | Idea stubs | Learnings filed | Archived |
|------|-------|-----------|------------|-----------------|---------|
| 2026-04-03 | 3 | 1 | 2 | 1 | ✓ |

One row per note. Show `—` for any column where nothing was found. If a note was empty and skipped processing, note that in the row.

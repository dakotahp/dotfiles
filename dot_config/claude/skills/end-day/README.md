# /end-day

End-of-day processing for the personal Obsidian vault. Reads the day's note, classifies every meaningful item into one of five content types, routes each type to the right destination, writes a structured distillation, and archives the note. Replaces the old "dump action items at the bottom" approach with a richer, typed summary.

## What it does

**Step 1 — Find unprocessed notes**
Looks in `0_Inbox/` for daily notes (files matching `YYYY-MM-DD.md`) that haven't been archived yet. Processes oldest first. Accepts an optional date argument (`/end-day 2026-04-03`) to process a specific day.

**Step 2 — Classify content**
Reads the full note and classifies every meaningful item into one of five types:

| Type | What it looks like |
|------|--------------------|
| **Hard todo** | Explicit next action — "I need to", "call X", "follow up on Z" |
| **Avoidance item** | Something that should happen but keeps getting deferred; guilty or reluctant tone |
| **Reflection** | Mood, mental state, observations about the day — not actionable |
| **Learning** | A fact, concept, or insight with a subject domain |
| **Idea fragment** | Half-formed thought without a clear next step — a "dust cloud" |

**Step 3 — Route each type**

- **Idea fragments** → stub notes in `0_Inbox/` tagged `#idea #stub`, with a source backlink. Captured for later cultivation rather than lost in the archive.
- **Avoidance items** → appended to `2_Areas/Personal Knowledge Management/Avoidance Radar.md` with the date first noted. Duplicates are skipped (fuzzy match).
- **Learnings** → appended to the relevant `2_Areas/` note with a `Source: [[date]]` backlink. The skill matches semantically — a learning about morning routines might go to Health & Fitness or Personal Knowledge Management.
- **Hard todos** and **Reflections** → stay in the note; surface in the Distillation.

**Step 4 — Write Distillation + archive**
Appends a `## Distillation` section to the note before archiving:

```markdown
## Distillation

**Day in brief:** [1–2 sentence synthesis of tone, main themes, energy level]

**Action items:**
- [ ] Item *(why it matters / what triggered it)*

**Avoiding** *(added to Avoidance Radar):*
- Item

**Ideas stubbed to Inbox:**
- [[Idea - Title]]

**Filed to 2_Areas:**
- [[Area Note]] ← learning summary
```

Then adds navigation links (`← prev | → next`) and moves the note to `4_Archive/Daily Notes/YYYY-MM/`. Back-fills the forward link on the previous day's archived note.

**Step 5 — Summary**
Shows a table of what was processed: dates, counts by type, archive status.

## Files this skill touches

| File | What happens |
|------|-------------|
| `0_Inbox/YYYY-MM-DD.md` | Read, Distillation appended, then moved to Archive |
| `4_Archive/Daily Notes/YYYY-MM/YYYY-MM-DD.md` | Destination after archiving |
| `0_Inbox/Idea - *.md` | Created for each idea fragment |
| `2_Areas/Personal Knowledge Management/Avoidance Radar.md` | Appended with avoidance items |
| `2_Areas/**/*.md` | Appended with learnings |

## Part of the skill trio

This skill is part of a three-skill daily/weekly workflow:

- **`/start-day`** — primes today's note with rolled-over todos, Radar items, and morning context
- **`/end-day`** — classifies, routes, distills, archives
- **`/end-week`** — weekly cofounder session; reads distillations, picks highest-leverage project, does real work

## Invocation

```
/end-day            # process today's note (and any unarchived prior notes)
/end-day 2026-04-03 # process a specific date
```

The only time it pauses to ask is when a learning can't be matched to a `2_Areas/` subfolder.

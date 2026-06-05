---
name: start-day
description: Use when starting the day to set up today's daily note and process any prior unprocessed notes.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, mcp__claude_ai_Google_Calendar__list_events
model: claude-sonnet-4-6
---

Morning startup for an Obsidian vault using the PARA structure. Runs in two phases: first closes out any unprocessed daily notes from prior days (routing content to its destination and archiving), then primes today's note with rolled-over todos, Avoidance Radar items, and context. Non-interactive except for ambiguous `2_Areas` folder matches.

**Vault resolution** — at the top of the run, determine which vault is active:

```bash
obsidian vaults
```

- If `ObsidianPersonal` appears, set `$VAULT=ObsidianPersonal` — this is the **personal vault** mode (Daily Spark, Life Domains, Quotes, inspiration all apply).
- Otherwise (e.g. `ObsidianWork`), set `$VAULT` to that vault name — this is **non-personal vault** mode (skip Daily Spark, skip Life Domains domain nudge, skip the templated Daily Note write — fall back to a simpler `obsidian daily` + append flow). Avoidance Radar still applies if the file exists.

All `vault=ObsidianPersonal` references below should be read as `vault=$VAULT` — substitute the resolved vault name throughout. Sections marked **[personal-vault only]** are skipped in non-personal mode.

Key rules:
- Vault parameter comes immediately after the subcommand: `obsidian <subcommand> vault=$VAULT [options]`
- Use `path=` for exact vault-relative paths; `file=` for wikilink-style name resolution
- Never run `obsidian --help` — it hangs and never exits

---

## Phase 1 — Close out unprocessed notes

### Step 1a — Find unprocessed daily notes and fire bootstrap reads

Fire all of the following in one parallel batch:

```bash
# Today's note path — extracts inbox folder and today's date
obsidian daily:path vault=ObsidianPersonal

# VAULT_PATH — needed for find commands below; strip the leading "=> " prefix
obsidian eval vault=ObsidianPersonal code="app.vault.adapter.basePath"

# Phase 2 bootstrap reads — fire now so results accumulate while Phase 1 runs
mcp__claude_ai_Google_Calendar__list_events(
  calendarId="dakotah.pena@apartmentiq.io",
  startTime="<today>T00:00:00",
  endTime="<today>T23:59:59",
  orderBy="startTime",
  timeZone="America/Los_Angeles"
)
obsidian read vault=ObsidianPersonal path="2_Areas/Quotes.md"
obsidian search vault=ObsidianPersonal folder="2_Areas" query="tag:#inspiration" format=json
obsidian read vault=ObsidianPersonal path="2_Areas/Life Domains.md"
obsidian search vault=ObsidianPersonal query="[agent-context:vault]" format=json

# Project canonical-file last-touched dates for staleness check.
# Convention: a project's canonical file is named after its folder, e.g.
# `1_Projects/Foo Project/Foo Project.md`. The `last-touched` frontmatter field
# is the source of truth — maintained by /log-project-session and /update-project-state skills.
# Projects with no last-touched field are skipped (no fallback to mtime).
obsidian eval vault=ObsidianPersonal code="JSON.stringify(app.vault.getFiles().filter(f => f.path.startsWith('1_Projects/') && f.parent && f.basename === f.parent.name).map(f => {const lt = app.metadataCache.getFileCache(f)?.frontmatter?.['last-touched'] ?? null; return {path: f.path, last_touched: lt};}).filter(f => f.last_touched).sort((a,b) => a.last_touched < b.last_touched ? -1 : 1))"

# Today's weather forecast — requires $WEATHER_LAT_LONG and $WEATHER_TZ env vars
curl -s "https://api.open-meteo.com/v1/forecast?${WEATHER_LAT_LONG}&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&${WEATHER_TZ}&forecast_days=1&temperature_unit=fahrenheit&precipitation_unit=inch" | jq -er '"High \(.daily.temperature_2m_max[0])°F, Low \(.daily.temperature_2m_min[0])°F, with a \(.daily.precipitation_probability_max[0])% chance of precipitation."'

# Today's max air quality index — requires $WEATHER_LAT_LONG env var
# Outputs a warning string only when AQI > 100 (Unhealthy for Sensitive Groups or worse); empty string otherwise
curl -s "https://air-quality-api.open-meteo.com/v1/air-quality?${WEATHER_LAT_LONG}&hourly=us_aqi&forecast_days=1" | jq -er '(.hourly.us_aqi | map(select(. != null)) | max) as $aqi | if $aqi <= 100 then "" elif $aqi <= 150 then "Air quality \($aqi) (unhealthy for sensitive groups)" elif $aqi <= 200 then "Air quality \($aqi) (unhealthy)" elif $aqi <= 300 then "Air quality \($aqi) (very unhealthy)" else "Air quality \($aqi) (hazardous)" end'
```

After VAULT_PATH resolves, fire this second batch (also in parallel):

```bash
# Inbox contents (Phase 1 input — folder derived from daily:path result)
obsidian files vault=ObsidianPersonal folder="0_Inbox"

# Current ISO week — capture stdout as CURRENT_WEEK label (shell vars don't persist across Bash tool calls)
date +%Y-%V

# Weekly notes folder listing
obsidian files vault=ObsidianPersonal folder="4_Archive/Weekly Notes"

# Project-scope agent-context files modified within 14 days
find "$VAULT_PATH/1_Projects" -name "*.md" -mtime -14 | xargs grep -l "^agent-context: project" 2>/dev/null
```

Store all results under these labels for use in Phase 2: **CALENDAR_EVENTS**, **VAULT_PATH**, **QUOTES_RAW**, **INSPIRATION_FILES**, **LIFE_DOMAINS**, **VAULT_AGENT_CONTEXT**, **PROJECT_LAST_TOUCHED**, **CURRENT_WEEK**, **WEEKLY_FILES**, **PROJECT_CONTEXT_FILES**, **WEATHER_FORECAST**, **AIR_QUALITY**. If any call fails, store empty/null and continue silently.

Filter the inbox list to files matching the `YYYY-MM-DD.md` pattern **where the date is before today**. Sort ascending (oldest first). These are unprocessed prior notes.

If none exist, skip to Phase 2.

### Step 1b — Process each prior note (oldest first, no pausing between notes)

The only exception to no-pausing is an ambiguous `2_Areas` folder match (see Step 1b-iii/iv).

**Track for each note:** count of todos, avoidance items, idea stubs, learnings filed. Carry extracted action items forward in memory — they feed directly into Phase 2.

**Multiple prior notes (2+):** Dispatch one Agent subagent per note (`model: haiku`) to run Steps 1b-i through 1b-iv concurrently. Each subagent creates stubs and files learnings directly. However, each subagent **returns avoidance items as output** rather than writing them — the main thread does a single Avoidance Radar read + batch append after all subagents finish (avoids write conflicts on a shared file). After all subagents complete, the main thread runs Step 1b-v (distillation + archive) for each note in date order.

#### Step 1b-i — Read, resolve wikilinks, and classify

```bash
obsidian read vault=ObsidianPersonal path="0_Inbox/YYYY-MM-DD.md"
```

If the note is empty or contains only a template skeleton with no substantive content, skip to Step 1b-v (archiving).

**Wikilink batch search** — extract ALL `[[...]]` references from the note text at once. Launch all searches simultaneously in one parallel batch (both folders for every link at the same time):

```bash
obsidian search vault=ObsidianPersonal folder="1_Projects" query="<link1>" format=json
obsidian search vault=ObsidianPersonal folder="2_Areas" query="<link1>" format=json
obsidian search vault=ObsidianPersonal folder="1_Projects" query="<link2>" format=json
obsidian search vault=ObsidianPersonal folder="2_Areas" query="<link2>" format=json
# … all links at once, not one at a time
```

If a match is found in either folder and is not already in the project context map, read the matched file and any sibling files with `agent-context: project` (or `agent-context: area` if under `2_Areas/`) in their frontmatter, then add them to the map. This surfaces projects referenced intentionally but outside the 14-day auto-load window.

**Classify** every meaningful item into one of five types (most specific match wins):

| Type | What it looks like |
|------|--------------------|
| **Hard todo** | An explicit next action: "I need to", "call X", "book Y", "follow up on Z" |
| **Avoidance item** | Something being put off — reappears across notes, reluctant tone |
| **Reflection** | Mood, mental state, day observations — not actionable |
| **Learning** | A fact, concept, or insight acquired from reading, a call, or experience |
| **Idea fragment** | A half-formed thought with no clear next step yet |

Items under `## Today's Priorities` are hard todos by default (unchecked only — skip `- [x]`).

**Completed work** — also collect all `- [x]` items from `## Today's Priorities` as a separate list. These are NOT rolled over, but ARE used to resolve open Avoidance Radar items in Step 1b-ii/iii/iv.

**Project attribution** — for each hard todo, fuzzy-match its text against project names in the project context map. A direct name mention, a wikilink to the project, or a domain clearly owned by one project all count. Tag each todo internally with its matched project, or mark it "unattributed" if no match.

#### Step 1b-ii/iii/iv — Create stubs, log avoidance, file learnings (parallel)

Run two batches in sequence:

**Read batch (fire together):**
```bash
obsidian read vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md"
obsidian files vault=ObsidianPersonal folder="2_Areas"
```

**Write batch (fire together after reads complete):**

All three write types target different files — fire them simultaneously.

*Idea stubs* — for each idea fragment:
```bash
obsidian create vault=ObsidianPersonal path="0_Inbox/Idea - <Short Title>.md" content="---\ntags:\n  - idea\n  - stub\nsource: \"[[YYYY-MM-DD]]\"\n---\n\n<raw thought, verbatim or lightly cleaned>" silent
```
Keep `<Short Title>` to 4–6 words. Don't expand or elaborate.

*Avoidance items* — fuzzy-match each item against the Radar content read above. If not already present, append:
```bash
obsidian append vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md" content="\n- [ ] <item> — *first noted: YYYY-MM-DD*"
```
If the Radar file doesn't exist, create it first:
```bash
obsidian create vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md" content="---\nagent-context: vault\n---\n\nThings that keep coming up but keep getting deferred. Reviewed weekly.\n" silent
```
**When running as a subagent (multi-note dispatch):** skip writing to the Radar entirely — return avoidance items (new) and completed todos (for resolution matching) as output to the main thread instead.

*Radar resolutions* — for each completed `[x]` todo collected in Step 1b-i, fuzzy-match against open `- [ ]` Radar items. A completed todo resolves a Radar item when:
- It references the same project and the Radar item is generic ("move something forward", "make progress on X", "do something on Y"), OR
- It names a specific deliverable that satisfies the Radar item's intent (e.g. "Write Ecclesiastes 5:10 post" resolves "Bible Verses Secular Relation Blog: move something forward")

When a match is found, update the Radar entry in-place — check the box and append the resolution annotation:
```bash
perl -i -pe 's|^- \[ \] (MATCHED_ITEM_PREFIX.*)|"- [x] $1, resolved: YYYY-MM-DD (completed in [[NOTE-DATE]])"|e' "$VAULT_PATH/2_Areas/Personal Knowledge Management/Avoidance Radar.md"
```
Use a literal prefix long enough to uniquely identify the line (avoid regex special chars). Fire resolution writes in the same batch as new avoidance appends — both target the Radar file but perl edits are safe to batch with appends since they operate on different lines.

**When running as a subagent:** skip all Radar writes — return completed todos alongside avoidance items for the main thread to process.

*Learnings* — match each learning semantically to a `2_Areas/` subfolder (from the files list). **Clear match:** proceed without asking. **No match:** suggest top 2 candidates or offer to create a new folder — this is the **only** pause point. Once answered, continue:
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

**Bootstrap batch results** from Step 1a should already be available. If any are still pending, wait for them now before continuing.

**Read vault agent-context files** — for each path returned in **VAULT_AGENT_CONTEXT**, read the file. These provide who-I-am, life-domain, and long-running-goals context.

**Read project-scope agent-context files** — for each path in **PROJECT_CONTEXT_FILES**, read the file. Build the **project context map**: project name (from path or frontmatter title) → key details (goal, current status, constraints, blockers). This map is shared across Phase 1 and Phase 2.

**Weekly note** — from **WEEKLY_FILES**, find the file matching `$CURRENT_WEEK.md`. If found, read it.

- **Extract `## Weekly Focus`** — if the section exists, take the single sentence beneath the heading and store as **WEEKLY_FOCUS_CONTENT** (the verbatim sentence, no heading, no surrounding whitespace). If the section is absent, the file is empty, or the weekly note doesn't exist at all, leave WEEKLY_FOCUS_CONTENT empty. This is the **only** content from the weekly note that gets replicated into today's daily note — it powers the `<!-- weekly-focus -->` placeholder.
- **Everything else is AMBIENT CONTEXT ONLY** — do not replicate other sections into today's daily note. It informs internal calibration: which rolled-over todos feel weightier (project matched `## Projects Focused`), which open `## Decisions Needed` items deserve attention, whether to flag a stale project (already covered by `## Archive Candidates`).

**Avoidance Radar** — read now (after Phase 1 has finished updating it):
```bash
obsidian read vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md"
```

**Rolled-over todos:**
- **If Phase 1 processed any notes:** use the action items already in memory from those Distillations — skip the archive re-read.
- **If Phase 1 had nothing to process:** list archived notes and read the most recent one to extract rolled-over todos:

```bash
obsidian files vault=ObsidianPersonal folder="4_Archive/Daily Notes"
obsidian read vault=ObsidianPersonal path="4_Archive/Daily Notes/YYYY-MM/YYYY-MM-DD.md"
```

Find `## Distillation` → `**Action items:**`, extract every `- [ ]` line verbatim.

**Recurring todo escalation** — before building priorities, check for todos stuck across 3+ days. Read the two archived Distillations immediately preceding the source note and extract their unchecked `- [ ]` action items. Any todo text that fuzzy-matches a rolled-over todo in both prior notes has been deferred for 3+ consecutive days — escalate it: append to Avoidance Radar (Step 1b-iii format, `first noted:` = today's date) and remove it from rolled-over todos. Skip this check if fewer than 2 prior archived Distillations exist.

### Step 2b-ii — Pick today's quote and inspiration **[personal-vault only]**

**Skip this entire step in non-personal vault mode.** Leave QUOTE_CONTENT, INSPIRATION_PATH, and INSPIRATION_TEASER empty/null.


**Quote** — from **QUOTES_RAW**, extract every line beginning with `- `. Strip the leading `- `. Use today's date as a seed: hash the full ISO date string (`YYYY-MM-DD`) and mod by the number of quotes — `int(hashlib.md5(date_str.encode()).hexdigest(), 16) % num_quotes` — then select that line. Same quote all day if the skill runs twice; different quotes across years on the same calendar date.

Store as **QUOTE_CONTENT** — the raw line text including attribution and any `[[wikilink]]`.

**Inspiration** — from **INSPIRATION_FILES**, apply the same full-date hash mod against the list to pick one file deterministically. Read **only the first non-frontmatter, non-heading line** of that file (skip `---` blocks and lines starting with `#`) — stop after the first prose paragraph; do not load the full file.

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

**De-duplicate Radar items against rolled-over todos** — before appending, drop any Radar item whose intent is already covered by a rolled-over todo. A Radar item is considered superseded when:
- A rolled-over todo references the same `[[Project]]` and the Radar item is generic ("move something forward", "make progress on X", "do something on Y"), OR
- A rolled-over todo names a specific deliverable that satisfies the Radar item's intent (e.g. "Write Ecclesiastes 5:10 post" supersedes "Bible Verses Secular Relation Blog: move something forward"), OR
- The project's most recent weekly note `## Work Produced` already lists a deliverable that satisfies the Radar item's intent — in this case, also flag the Radar item to the user in CONTEXT_CONTENT as potentially resolvable ("Resolved?: [item] — [deliverable] shipped").

When in doubt, prefer suppression: a stale Radar item next to its concrete rolled-over counterpart adds noise, not signal.

**Stale project flag** — from **PROJECT_LAST_TOUCHED** (canonical project files with a `last-touched` frontmatter field), compare each `last_touched` date string to today. If any is 30+ days old, pick the least stale qualifying project and add:

`- [ ] [[Project name]]: no activity in N days, worth a push?`

Skip if a rolled-over todo already references that project. Skip if all projects with a `last-touched` field are under 30 days. Projects with no `last-touched` field are ignored entirely.

**Cap** — if PRIORITIES_CONTENT exceeds 6 items, remove from the bottom: youngest Radar items first, then stale flag. Never drop rolled-over todos.

**CONTEXT_CONTENT:**
- **Line 1 (personal-vault only):** One sentence from Life Domains `## Current Context` — the single most time-sensitive or seasonally relevant point. Skip in non-personal mode.
- **Line 2 (conditional):** Only if any Radar item is 14+ days old: `Overdue: [item name] (N days), [item name] (N days).` Omit entirely if nothing qualifies.

**MEETINGS_CONTENT** — derived separately from CALENDAR_EVENTS:
- If CALENDAR_EVENTS is non-empty: `**Meetings:** HH:MM Event title, HH:MM Event title` — list each event's start time (12-hour, no seconds) and summary, comma-separated.
- If CALENDAR_EVENTS is empty: substitute an empty string for `<!-- meetings -->`.

### Step 2d — Write to today's note

Get today's note path:
```bash
obsidian daily:path vault=ObsidianPersonal
```

Full filesystem path: `$VAULT_PATH/` + returned path (reuse **VAULT_PATH** from Step 1a).

Use a single Python script to do all substitutions and write the final file for **all vaults**. Always read from the **template file directly** — do not patch the `obsidian daily`-created file, which has a known CLI bug that double-encodes multibyte characters (emoji, `°`, curly quotes) and will corrupt the note.

Template path: `$VAULT_PATH/3_Resources/Obsidian Templates/Daily Note Template.md`

`replace()` calls are no-ops when a placeholder isn't present in the template, so the same script works across vaults. Personal-vault-only placeholders (`<!-- quote -->`, `<!-- inspiration -->`) simply go unused in non-personal templates. If a value is empty/null, substitute an empty string.

**WEEKLY_FOCUS_LINE** — derive from WEEKLY_FOCUS_CONTENT (extracted in Step 2b):
- If WEEKLY_FOCUS_CONTENT is non-empty: `WEEKLY_FOCUS_LINE = f"{WEEKLY_FOCUS_CONTENT} — [[{CURRENT_WEEK}]]"` — focus sentence followed by a wikilink to the weekly note.
- If empty (no weekly note, or no `## Weekly Focus` section): substitute an empty string.

**INSPIRATION_FILENAME** is the bare note name (no path, no `.md`) for the wikilink. The `*italics*` wrapper around `<!-- quote -->` is already in the personal template.

**YESTERDAY_DATE** / **TOMORROW_DATE** — `YYYY-MM-DD` strings for the calendar day before and after today. Compute from today's date (e.g. `(date.today() - timedelta(days=1)).isoformat()`).

```python
python3 << 'PYEOF'
vault = "$VAULT_PATH"
template_path = f"{vault}/3_Resources/Obsidian Templates/Daily Note Template.md"
note_path = f"{vault}/<TODAY_VAULT_PATH>"

with open(template_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('<!-- weekly-focus -->', 'WEEKLY_FOCUS_LINE')
content = content.replace('<!-- quote -->', 'QUOTE_CONTENT')
content = content.replace('<!-- inspiration -->', '[[INSPIRATION_FILENAME]] — INSPIRATION_TEASER')
content = content.replace('<!-- weather -->', 'WEATHER_FORECAST')
content = content.replace('<!-- air -->', 'AIR_QUALITY')
content = content.replace('<!-- priorities -->', 'PRIORITIES_CONTENT')
content = content.replace('<!-- context -->', 'CONTEXT_CONTENT')
content = content.replace('<!-- meetings -->', 'MEETINGS_CONTENT')
content = content.replace('<!-- prev-date -->', 'YESTERDAY_DATE')
content = content.replace('<!-- next-date -->', 'TOMORROW_DATE')

with open(note_path, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF
```

Embed all content values directly into the heredoc before running — do not use shell variable interpolation for the replacement strings, as they may contain characters that break shell quoting. If the note does **not** contain `<!-- prev-date -->`, the placeholders have already been replaced and the skill already ran today — skip the write entirely.

---

## Phase 3 — Summary

If Phase 1 processed any notes, show the processing table:

| Date | Todos | Avoidance | Idea stubs | Learnings filed | Archived |
|------|-------|-----------|------------|-----------------|---------|
| 2026-04-10 | 2 | — | — | — | ✓ |

One row per note. Show `—` for columns with nothing found. If a note was empty and skipped processing, note that in the row.

If Phase 1 had nothing to process, no summary needed — the note is ready silently.

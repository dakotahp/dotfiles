---
description: Load project context from summary file + recent session logs via Obsidian CLI
model: opus
allowed-tools: Bash
---

# /resume - Resume Work with Full Context

Loads the project's canonical summary file and recent session logs to get up to speed quickly.

**Usage:**
- `/resume` — summary file + last 3 session logs
- `/resume 5` — summary file + last 5 session logs
- `/resume auth` — summary file + last 3 + search for "auth" in past sessions
- `/resume 10 migration` — summary file + last 10 + search for "migration"

## Instructions for Claude

### Step 0: Verify Obsidian Is Running

```bash
obsidian version
```

If this fails, stop and tell the user: "Obsidian doesn't appear to be running. Please open it and try again."

### Step 1: Parse Arguments

Check if the user provided arguments after `/resume`:
- **Number (N):** How many recent sessions to load (default: 3, max: 50)
- **Topic keyword:** Search for related sessions beyond the last N

Examples:
- `/resume` → N=3, no topic search
- `/resume 5` → N=5, no topic search
- `/resume auth` → N=3, topic="auth"
- `/resume 10 jira` → N=10, topic="jira"

### Step 2: Detect Project and Read Summary File

1. Get the current working directory via `pwd`
2. Extract the folder name (last path component) as the **project name**
3. Read the summary file:
   ```bash
   obsidian read file="{ProjectName}" vault="ObsidianWork"
   ```

If the user provides a vault name override, use that instead of `ObsidianWork` throughout.

**If the summary file is not found:**
```
No summary file "{ProjectName}.md" found in this project folder.

Options:
1. Tell me about this project and I'll help create one
2. Just start working and run /preserve later

What would you like to do?
```

Extract from the summary file:
- Project purpose/description
- Current phase/status
- Key references and paths
- The `## Session Context` section (if it exists) — status, blockers, next steps

### Step 3: Find Session Logs

List session log files in the project's `Session Logs/` folder:
```bash
ls -1r "{absolute-path-to-project}/Session Logs/"*.md 2>/dev/null
```

Files are named `YYYY-MM-DD-HH_MM-{topic}.md`, so reverse-sorted `ls` gives newest first.

**If no session logs exist** (folder missing or empty):
- Skip all session log sections
- Note: "No session logs yet. Run /compress to start building session history."

### Step 4: Read Last N Session Logs

For each of the last N session log files:
1. Read the full file via:
   ```bash
   obsidian read path="{vault-relative-path-to-session-log}" vault="ObsidianWork"
   ```
2. Extract:
   - **Date and topic** (from filename: `YYYY-MM-DD-HH_MM-{topic}.md`)
   - **Keywords** (from Quick Reference section)
   - **Outcome** (from Quick Reference section)
   - **Key decisions** (if present)
   - **Pending tasks** (if present)
   - **Quick Resume Context** (the 2-3 sentence summary)

If fewer than N logs exist, read all available and note: "Found {X} session logs (requested {N})"

### Step 5: Topic Search (If Keyword Provided)

If the user provided a topic keyword:

```bash
obsidian search query="{keyword}" vault="ObsidianWork"
```

Filter results to only files within this project's `Session Logs/` folder. For each matched session not already in the last N, read it and extract the same fields as Step 4.

### Step 6: Output Combined Report

```
══════════════════════════════════════════════
 RESUMING: {Project Name}
══════════════════════════════════════════════

CONTEXT (from {ProjectName}.md):
- {Key insight from summary file}
- {Current status/phase}
- {Important project state}

SESSION STATE:
- Status: {from Session Context section, or "No session context yet"}
- Blockers: {any blockers, or "None"}
- Next steps: {action items}

══════════════════════════════════════════════
 MOST RECENT SESSION: {YYYY-MM-DD HH:MM}
 Topic: {Topic Name}
══════════════════════════════════════════════

**Keywords:** {keywords}
**Outcome:** {outcome}

**Key Points:**
- {Decision or learning 1}
- {Decision or learning 2}
- {Pending task if any}

══════════════════════════════════════════════
 PREVIOUS SESSIONS ({count} more)
══════════════════════════════════════════════

- {YYYY-MM-DD}: {Topic} — {Outcome snippet}
- {YYYY-MM-DD}: {Topic} — {Outcome snippet}

{Only if topic search was performed and found results:}
══════════════════════════════════════════════
 RELATED SESSIONS (Topic: "{keyword}")
══════════════════════════════════════════════

- {YYYY-MM-DD}: {Topic} — {Why it matched}
- {YYYY-MM-DD}: {Topic} — {Why it matched}

══════════════════════════════════════════════
 READY TO:
══════════════════════════════════════════════

- {Next step from summary file}
- {Pending task from recent session}
- {Additional next steps}

══════════════════════════════════════════════
```

### Handling Variations

- **No summary file:** Show the "not found" prompt from Step 2, do not output the report
- **Summary file exists but no Session Context section:** Show "No session context yet" in SESSION STATE
- **No session logs:** Skip the MOST RECENT SESSION and PREVIOUS SESSIONS blocks entirely
- **Fewer than N logs:** Show all available, note the count
- **Topic search with no matches:** Note "No sessions found matching '{keyword}'"
- **Only 1 session log:** Show it as MOST RECENT SESSION, skip PREVIOUS SESSIONS block

---

## Filename Parsing

Session log filenames follow: `YYYY-MM-DD-HH_MM-topic-name.md`

Parse to extract:
- **Date:** `YYYY-MM-DD`
- **Time:** `HH:MM` (replace `_` with `:`)
- **Topic:** Everything after the time portion, with hyphens replaced by spaces

Example: `2026-04-24-14_30-api-auth-refactor.md`
- Date: 2026-04-24
- Time: 14:30
- Topic: api auth refactor

---

## Performance Notes

- **Default N=3:** Keeps token usage low while providing recent context
- **Max N=50:** Reasonable upper limit for scanning
- **Full file reads are fine:** Session logs contain no raw transcripts, so they're compact
- **Obsidian search** handles keyword matching efficiently across the vault

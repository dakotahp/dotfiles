---
description: Load project context from summary file + recent session logs via Obsidian CLI
model: opus
allowed-tools: Bash
---

# /resume - Resume Work with Full Context

Loads the project's canonical summary file and recent session logs to get up to speed quickly.

**Usage:**
- `/resume` — summary file + last 3 session logs (project derived from cwd)
- `/resume 5` — summary file + last 5 session logs
- `/resume auth` — summary file + last 3 + search for "auth" in past sessions
- `/resume 10 migration` — summary file + last 10 + search for "migration"
- `/resume "Real Estate Operating Company"` — explicit project, last 3 logs (works from anywhere)
- `/resume "Real Estate Operating Company" 5 migration` — explicit project + N + topic

## Instructions for Claude

### Step 1: Parse Arguments

`$ARGUMENTS` may contain, in order:

1. **Optional quoted project name** — if `$ARGUMENTS` starts with `"`, take everything up to the next `"` as the project name. Strip it (and surrounding whitespace) from `$ARGUMENTS` before parsing the rest.
2. **Number (N):** How many recent sessions to load (default: 3, max: 50)
3. **Topic keyword:** Search for related sessions beyond the last N

Examples:
- `/resume` → project from cwd, N=3, no topic
- `/resume 5` → project from cwd, N=5, no topic
- `/resume auth` → project from cwd, N=3, topic="auth"
- `/resume 10 jira` → project from cwd, N=10, topic="jira"
- `/resume "My Project"` → project="My Project", N=3, no topic
- `/resume "My Project" 5 auth` → project="My Project", N=5, topic="auth"

### Step 2: Resolve Project Context

This skill operates on a **project** under `1_Projects/` or an **area** under `2_Areas/`. Both must be folder-form: `<category>/<name>/<name>.md`.

**2a. Determine the project name:**

- If a quoted project name was extracted in Step 1, use it.
- Otherwise, derive from `pwd`: walk up from cwd. If an ancestor folder is named `1_Projects` or `2_Areas`, the immediate child folder is the project name.
- If neither yields a project, error and stop:
  ```
  No project specified. Run from inside a 1_Projects/ or 2_Areas/ folder, or pass the project name: /resume "Project Name"
  ```

**2b. Determine the vault and category:**

- If the walk-up succeeded, the vault root is the parent of the matched `1_Projects` or `2_Areas` folder. The vault name is that root's basename. The category is whichever of `1_Projects` / `2_Areas` was matched.
- Otherwise (arg-mode from outside any vault):
  1. Run `obsidian vaults verbose` to list vaults and their absolute paths.
  2. For each vault, check whether `<vault path>/1_Projects/<project>/<project>.md` or `<vault path>/2_Areas/<project>/<project>.md` exists on disk.
  3. Exactly one match → use that vault and category.
  4. Multiple matches → error: `"Found '<project>' in multiple vaults: <list>. Run from inside the project folder to disambiguate."`
  5. No match → error: `"No folder-form project or area named '<project>' found in any vault."`

**2c. Set placeholders:**

- `{Vault}` — resolved vault name
- `{Category}` — `1_Projects` or `2_Areas`
- `{ProjectName}` — the project/area name
- `{ProjectPath}` — `{Category}/{ProjectName}` (vault-relative)
- `{ProjectAbsPath}` — absolute filesystem path to the project folder (for `ls` of session logs)

**2d. Read the summary file:**

```bash
obsidian read path="{ProjectPath}/{ProjectName}.md" vault="{Vault}"
```

**If the summary file is not found:**
```
No summary file "{ProjectPath}/{ProjectName}.md" found.

Options:
1. Tell me about this project and I'll help create one
2. Just start working and run /snapshot later

What would you like to do?
```

Extract from the summary file:
- Project purpose/description
- Current phase/status
- Key references and paths
- The `## Session Context` section (if it exists) — status, blockers, next steps
- The `last-touched` frontmatter property (if present)

**Stale check:** if `last-touched` is present and more than 30 days before today, set a `STALE_WARNING` flag with the day count. Surface it prominently in the Step 6 report (see CONTEXT block). If `last-touched` is absent, no warning — the project simply hasn't had a session-skill run yet.

### Step 3: Find Session Logs

List session log files in the project's `Session Logs/` folder:
```bash
ls -1r "{ProjectAbsPath}/Session Logs/"*.md 2>/dev/null
```

Files are named `YYYY-MM-DD-HH_MM-{topic}.md`, so reverse-sorted `ls` gives newest first.

**If no session logs exist** (folder missing or empty):
- Skip all session log sections
- Note: "No session logs yet. Run /log to start building session history."

### Step 4: Read Last N Session Logs

For each of the last N session log files:
1. Read the full file via:
   ```bash
   obsidian read path="{ProjectPath}/Session Logs/{filename}" vault="{Vault}"
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
obsidian search query="{keyword}" vault="{Vault}"
```

Filter results to only files within `{ProjectPath}/Session Logs/`. For each matched session not already in the last N, read it and extract the same fields as Step 4.

### Step 5.5: Link to Today's Daily Note (Side Effect)

Resuming a project counts as touching it. Append a backlink to today's daily note so the project's backlink graph naturally records engagement. Best-effort and silent on failure.

**a. Check whether today's daily note exists in `{Vault}`:**

```bash
obsidian daily vault="{Vault}"
```

- If the command errors or indicates no daily note exists, **skip silently**. Do NOT create one — that is `start-day`'s job. Some vaults (e.g., work) may not use daily notes.

**b. Idempotency:** if the daily note content already contains `[[{ProjectName}]]`, skip.

**c. Append:** if `## Sessions` exists, add `- [[{ProjectName}]]` under it. Otherwise append a new `## Sessions` section with the bullet:

```bash
obsidian daily:append vault="{Vault}" content="

## Sessions
- [[{ProjectName}]]"
```

**d. Swallow errors.** This is a side effect; never block the resume report.

### Step 6: Output Combined Report

```
══════════════════════════════════════════════
 RESUMING: {ProjectName}  ({Vault} → {ProjectPath})
══════════════════════════════════════════════

CONTEXT (from {ProjectName}.md):
{If STALE_WARNING is set, prepend this line in bold:}
⚠ **Stale: last touched {N} days ago ({YYYY-MM-DD}).** Re-orient before assuming session context is current.
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

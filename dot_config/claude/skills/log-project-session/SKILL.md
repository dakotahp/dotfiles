---
description: Save a structured session log to a project's or area's Session Logs folder via Obsidian CLI
model: sonnet
allowed-tools: Bash, AskUserQuestion
---

# /log-project-session - Save Structured Session Log

Captures key session content into a searchable log file in the project's or area's `Session Logs/` folder. No raw conversation transcript — only structured, extracted insights. Works identically for `1_Projects/<name>/` and `2_Areas/<name>/` — only the surrounding labels differ.

Captures **events** (what happened in a session). For **state** (where the project is now), use `/update-project-state`.

**Independent skill.** Can run alone or alongside `/update-project-state`. Does not depend on or trigger any other skill.

## Instructions for Claude

### Step 1: Resolve Project/Area Context

This skill operates on a **project** under `1_Projects/` or an **area** under `2_Areas/`. Both must be folder-form: `<category>/<name>/<name>.md`. Other top-level folders (`0_Inbox/`, `3_Resources/`, `4_Archive/`) are not supported.

**1a. Determine the project/area name:**

- If `$ARGUMENTS` is provided, treat the entire argument string as the project/area name.
- Otherwise, derive from `pwd`: walk up from cwd. If an ancestor folder is named `1_Projects` or `2_Areas`, the immediate child folder is the project/area name. If cwd is the vault root and the user's recent activity in the conversation clearly identifies a single project or area folder, you may use that as the inferred target — but only when it's unambiguous; otherwise error.
- If neither yields a target, error and stop:
  ```
  No project or area specified. Run from inside a 1_Projects/ or 2_Areas/ folder, or pass the name: /log-project-session "Name"
  ```

**1b. Determine the vault and category:**

- If the walk-up succeeded, the vault root is the parent of the matched `1_Projects` or `2_Areas` folder. The vault name is that root's basename. The category is whichever of `1_Projects` / `2_Areas` was matched.
- Otherwise (arg-mode from outside any vault):
  1. Run `obsidian vaults verbose` to list vaults and their absolute paths.
  2. For each vault, check whether `<vault path>/1_Projects/<project>/` or `<vault path>/2_Areas/<project>/` exists on disk.
  3. Exactly one match → use that vault and category.
  4. Multiple matches → error: `"Found '<project>' in multiple vaults: <list>. Run from inside the project folder to disambiguate."`
  5. No match → error: `"No folder-form project or area named '<project>' found in any vault."`

**1c. Set the placeholders used in later steps:**

- `{Vault}` — resolved vault name
- `{Category}` — `1_Projects` or `2_Areas`
- `{ProjectName}` — the project/area name (kept as `ProjectName` for placeholder continuity; refers to either)
- `{ProjectPath}` — `{Category}/{ProjectName}` (vault-relative)
- `{CategoryLabel}` — `Project` if `{Category}` is `1_Projects`, else `Area`. Used in user-facing confirmation output.

### Step 2: Ask What to Capture

Use AskUserQuestion with multi-select:

**Question:** "What would you like to capture from this session?"

**Options:**
1. **Key Learnings** — technical insights, new knowledge, "aha" moments
2. **Solutions & Fixes** — code solutions, bug fixes, commands that worked
3. **Decisions Made** — choices, trade-offs, why X over Y
4. **Files Modified** — list of files created/edited with brief descriptions
5. **Setup & Config** — environment setup, paths, configurations
6. **Pending Tasks** — unfinished work, next steps, blockers
7. **Errors & Workarounds** — problems encountered and how they were solved

### Step 3: Ask for Topic Name and Outcome

Ask the following questions **one at a time** using AskUserQuestion:

1. "What's a short topic name for this session? (3-5 words, e.g. `api-auth-refactor`)"
2. "One sentence: what was the outcome of this session?"

### Step 4: Gather Section Content

For each section the user selected in Step 2, ask a focused question using AskUserQuestion. Ask all selected sections **one at a time**:

- **Key Learnings:** "What were the key learnings or insights? (one per line, or 'skip')"
- **Solutions & Fixes:** "What solutions or fixes worked? Include commands or code snippets. (one per line, or 'skip')"
- **Decisions Made:** "What decisions were made, and why? (one per line, or 'skip')"
- **Files Modified:** "Which files were created or changed, and what did you do to each? (one per line, or 'skip')"
- **Setup & Config:** "Any environment setup, paths, or config to record? (one per line, or 'skip')"
- **Pending Tasks:** "What's unfinished or needs follow-up? (one per line, or 'skip')"
- **Errors & Workarounds:** "Any errors encountered and how you resolved them? (one per line, or 'skip')"

After gathering all sections, ask: "Anything else specific you want to highlight or remember? (or 'skip')" — this becomes **Custom Notes**.

Finally ask: "Any keywords to tag this session? (project names, tools, action types — space-separated, or 'skip')"

### Step 5: Generate Session Log Content

Assemble the session log from the user's answers. Create the session log with this structure:

```markdown
# Session Log: YYYY-MM-DD HH:MM - {Topic Name}

## Quick Reference
**Keywords:** {extracted keywords}
**Outcome:** {1-sentence outcome summary}

## Decisions Made
- {Decision 1 with brief rationale}
- {Decision 2 with brief rationale}

## Key Learnings
- {Learning 1}
- {Learning 2}

## Solutions & Fixes
- {Solution 1}
- {Solution 2}

## Files Modified
- `{path/to/file}`: {what changed}

## Setup & Config
- {Config item}

## Pending Tasks
- {Pending item}

## Errors & Workarounds
- {Error and fix}

## Key Exchanges
- {Notable exchange 1, brief summary}
- {Notable exchange 2, brief summary}

## Custom Notes
{User's custom notes from Step 2, or "None"}

---

## Quick Resume Context
{2-3 sentences that would help resume this work in a future session}
```

**Rules:**
- Only include sections the user selected in Step 2
- **Always include:** Quick Reference and Quick Resume Context (regardless of selection)
- Be concise: each bullet should be actionable or informative
- Use code blocks for commands, paths, and code snippets
- Preserve exact values — don't paraphrase specific configs, IDs, or identifiers
- If something depends on something else, note the relationship

### Step 6: Finalize Keywords

Use the keywords the user provided in Step 4. If the user skipped, derive a minimal set from the topic name and outcome sentence only — do not analyze conversation history.

### Step 7: Save the Session Log

Use the `{Vault}` and `{ProjectPath}` resolved in Step 1.

**Generate filename:**
```
YYYY-MM-DD-HH_MM-{topic-name}.md
```
Example: `2026-04-24-14_30-api-auth-refactor.md`

**Get the current time:**
```bash
date +"%Y-%m-%d-%H_%M"
```

**Save via Obsidian CLI:**
```bash
obsidian create path="{ProjectPath}/Session Logs/{filename}" content="{session log content}" vault="{Vault}" silent
```

The `obsidian create` command will create the `Session Logs/` folder if it doesn't exist.

### Step 7.25: Update `last-touched` Frontmatter on Canonical File

Stamp the canonical project/area file with today's date. Authoritative engagement signal consumed by `/continue-project` (stale-warning) and `/end-week` (neglect scoring). Applies equally to projects and areas — both have a canonical `{ProjectName}.md` at the root of their folder.

**Never use `obsidian property:set`** — it is known to destroy the file body on success. Instead, do an atomic read → modify-frontmatter-in-memory → write-back, mirroring `/update-project-state` Step 6:

**a. Read the file:**
```bash
obsidian read path="{ProjectPath}/{ProjectName}.md" vault="{Vault}"
```

**b. Update the frontmatter in memory:** if a `---`-delimited frontmatter block exists at the top of the file, set (or add) `last-touched: YYYY-MM-DD`. If no frontmatter block exists, prepend one containing only that property. Preserve every other frontmatter property and the entire file body exactly as-is.

**c. Write back atomically:**
```bash
obsidian create path="{ProjectPath}/{ProjectName}.md" content="{full reconstructed content}" vault="{Vault}" overwrite silent
```

**d. Verify the write was not destructive** by reading the file back and confirming the body length matches what was reconstructed. If anything looks wrong, **stop and report to the user** — do not proceed silently.

Swallow non-destructive errors (e.g., file not found) — a failure here should not block the session-log save. But never swallow a verify failure: a truncated canonical file is worse than a missing date stamp.

### Step 7.5: Link to Today's Daily Note (Side Effect)

Build a passive event log of project engagement so backlinks on the project file naturally accumulate "when did I touch this." Best-effort and silent on failure.

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

**d. Swallow errors.** This is a side effect; never block the save.

### Step 8: Confirm

Output confirmation, substituting `{CategoryLabel}` (e.g. `Project:` or `Area:`):

```
Session Saved

File:        Session Logs/{filename}
{CategoryLabel}: {ProjectName}
Topic:       {topic-name}
Sections:    {list of selected sections}
Keywords:    {keywords}

Use /continue-project to load context from this and other sessions.
```

---

## Guidelines

- **Be concise.** Each bullet should be actionable or informative
- **Use code blocks** for commands, paths, and code snippets
- **Include file paths** with line numbers where relevant
- **Preserve exact values.** Don't paraphrase credentials, IDs, or specific configs
- **Link context.** If something depends on something else, note the relationship
- **Extract keywords thoroughly.** The Keywords field is critical for future search via `/continue-project`
- **No raw session log.** The structured sections ARE the record. No conversation transcript.

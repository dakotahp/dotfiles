---
context: conversation
description: Save a structured session log to your project's Session Logs folder via Obsidian CLI
model: opus
allowed-tools: Bash, AskUserQuestion
---

# /compress - Save Structured Session Log

Captures key session content into a searchable log file in the project's `Session Logs/` folder. No raw conversation transcript — only structured, extracted insights.

**Independent skill.** Can run alone or after `/preserve`. Does not depend on or trigger any other skill.

## Instructions for Claude

### Step 1: Resolve Project Context

This skill operates on a **project** under `1_Projects/` or an **area** under `2_Areas/`. Both must be folder-form: `<category>/<name>/<name>.md`. Other top-level folders (`0_Inbox/`, `3_Resources/`, `4_Archive/`) are not supported.

**1a. Determine the project name:**

- If `$ARGUMENTS` is provided, treat the entire argument string as the project name.
- Otherwise, derive from `pwd`: walk up from cwd. If an ancestor folder is named `1_Projects` or `2_Areas`, the immediate child folder is the project name.
- If neither yields a project, error and stop:
  ```
  No project specified. Run from inside a 1_Projects/ or 2_Areas/ folder, or pass the project name: /compress "Project Name"
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
- `{ProjectName}` — the project/area name
- `{ProjectPath}` — `{Category}/{ProjectName}` (vault-relative)

### Step 2: Ask What to Preserve

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

### Step 3: Ask for Custom Notes (Optional)

Ask: "Anything specific you want to highlight or remember? (Type 'skip' to continue)"

### Step 4: Suggest Topic Name

Analyze the conversation and suggest a concise topic name (3-5 words, lowercase, hyphens):

```
Based on this session, I suggest the topic name: **api-auth-refactor**

Accept this, or type your preferred topic name:
```

The user can accept with "ok"/"yes" or provide their own.

### Step 5: Generate Session Log Content

Create the session log with this structure:

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

### Step 6: Extract Keywords

For the Quick Reference **Keywords** field, extract from the conversation:
- Project/product names
- Technical terms (auth, middleware, migration, deploy)
- Action types (refactor, fix, create, update)
- Tool/framework names (React, PostgreSQL, Docker)
- Ticket/issue identifiers (JIRA-123, #456)
- People mentioned (if relevant to decisions)

These keywords enable `/resume` to find relevant sessions via search.

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

Output confirmation:

```
Session Saved

File: Session Logs/{filename}
Project: {project name}
Topic: {topic-name}
Sections: {list of selected sections}
Keywords: {confidence keywords}

Use /resume to load context from this and other sessions.
```

---

## Guidelines

- **Be concise.** Each bullet should be actionable or informative
- **Use code blocks** for commands, paths, and code snippets
- **Include file paths** with line numbers where relevant
- **Preserve exact values.** Don't paraphrase credentials, IDs, or specific configs
- **Link context.** If something depends on something else, note the relationship
- **Extract keywords thoroughly.** The Keywords field is critical for future search via `/resume`
- **No raw session log.** The structured sections ARE the record. No conversation transcript.

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

### Step 0: Verify Obsidian Is Running

```bash
obsidian version
```

If this fails, stop and tell the user: "Obsidian doesn't appear to be running. Please open it and try again."

### Step 1: Ask What to Preserve

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

### Step 2: Ask for Custom Notes (Optional)

Ask: "Anything specific you want to highlight or remember? (Type 'skip' to continue)"

### Step 3: Suggest Topic Name

Analyze the conversation and suggest a concise topic name (3-5 words, lowercase, hyphens):

```
Based on this session, I suggest the topic name: **api-auth-refactor**

Accept this, or type your preferred topic name:
```

The user can accept with "ok"/"yes" or provide their own.

### Step 4: Generate Session Log Content

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
- Only include sections the user selected in Step 1
- **Always include:** Quick Reference and Quick Resume Context (regardless of selection)
- Be concise: each bullet should be actionable or informative
- Use code blocks for commands, paths, and code snippets
- Preserve exact values — don't paraphrase specific configs, IDs, or identifiers
- If something depends on something else, note the relationship

### Step 5: Extract Keywords

For the Quick Reference **Keywords** field, extract from the conversation:
- Project/product names
- Technical terms (auth, middleware, migration, deploy)
- Action types (refactor, fix, create, update)
- Tool/framework names (React, PostgreSQL, Docker)
- Ticket/issue identifiers (JIRA-123, #456)
- People mentioned (if relevant to decisions)

These keywords enable `/resume` to find relevant sessions via search.

### Step 6: Detect Project Path and Save

1. Get the current working directory via `pwd`
2. Extract the folder name as the project name
3. Determine the vault-relative project path

**Generate filename:**
```
YYYY-MM-DD-HH_MM-{topic-name}.md
```
Example: `2026-04-24-14_30-api-auth-refactor.md`

**Get the current time:**
```bash
date +"%Y-%m-%d-%H_%M"
```

**Construct the vault-relative path** for the session log. The path is relative to the vault root. For example, if working in `1_Projects/Feature Seed Data/`, the path would be:
```
1_Projects/Feature Seed Data/Session Logs/2026-04-24-14_30-api-auth-refactor.md
```

**Save via Obsidian CLI:**
```bash
obsidian create path="{vault-relative-project-path}/Session Logs/{filename}" content="{session log content}" vault="ObsidianWork" silent
```

The `obsidian create` command will create the `Session Logs/` folder if it doesn't exist.

### Step 7: Confirm

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

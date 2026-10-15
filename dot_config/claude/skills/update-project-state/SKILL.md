---
context: conversation
description: Update the project's current state (phase, decisions, blockers, next steps) in its canonical summary file. Replaces, does not accumulate. Use when state has changed; for events (what happened in a session) use /log-project-session.
model: opus
allowed-tools: Bash, AskUserQuestion, mcp__obsidian-vault
---

# /update-project-state - Update Project State

Updates the project's canonical summary file with the current state of understanding. Writes a `## Session Context` section that represents where the project stands *now*, replaced (not accumulated) on each run. This captures **state** (where the project is). For **events** (what happened in a session), use `/log-project-session`.

**Independent skill.** Can run alone or alongside `/log-project-session`. Does not depend on or trigger any other skill.

## Instructions for Claude

### Step 1: Resolve Project Context

This skill operates on a **project** under `1_Projects/` or an **area** under `2_Areas/`. Both must be folder-form: `<category>/<name>/<name>.md`. Other top-level folders (`0_Inbox/`, `3_Resources/`, `4_Archive/`) are not supported.

**1a. Determine the project name:**

- If `$ARGUMENTS` is provided, treat the entire argument string as the project name.
- Otherwise, derive from `pwd`: walk up from cwd. If an ancestor folder is named `1_Projects` or `2_Areas`, the immediate child folder is the project name.
- If neither yields a project, error and stop:
  ```
  No project specified. Run from inside a 1_Projects/ or 2_Areas/ folder, or pass the project name: /update-project-state "Project Name"
  ```

**1b. Determine the vault and category:**

Check both vaults, `Work` and `Personal`, for `1_Projects/<project>/<project>.md` and `2_Areas/<project>/<project>.md` with `get_frontmatter`. If the walk-up in 1a matched a category, check only that one.

1. Exactly one match → use that vault and category.
2. Multiple matches → ask which vault to use.
3. No match → error: `"No folder-form project or area named '<project>' found in any vault."`

**1c. Set the placeholders used in later steps:**

- `{Vault}`: resolved vault name (`Work` or `Personal`)
- `{Category}`: `1_Projects` or `2_Areas`
- `{ProjectName}`: the project/area name
- `{ProjectPath}`: `{Category}/{ProjectName}` (vault-relative)

**1d. Verify the summary file exists:** read `{ProjectPath}/{ProjectName}.md` in `{Vault}` with `read_note`.

If not found, ask the user:
"No summary file `{ProjectPath}/{ProjectName}.md` found. Would you like me to create one, or specify a different file?"

### Step 2: Ask What to Capture in the Snapshot

Use AskUserQuestion with multi-select:

**Question:** "What should this snapshot capture?"

**Options:**
1. **Phase/Status Changes**, what moved forward, what's now complete
2. **Key Decisions**, choices made and why (for future reference)
3. **New Files/Structure**, what was created or changed
4. **Patterns/Insights**, reusable learnings, "aha" moments
5. **Blockers/Warnings**, issues for future sessions
6. **Next Steps**, clear action items

### Step 3: Ask for Custom Notes (Optional)

Ask: "Anything specific you want to highlight or remember? (Type 'skip' to continue)"

### Step 4: Read Current Summary File

Read the full content of the summary file with `read_note`.

Understand:
- What sections exist
- Whether a `## Session Context` section already exists
- The general structure and tone of the file

### Step 5: Generate the Session Context Section

Based on the user's selections, generate the section content:

```markdown
## Session Context

**Status:** {current phase/status}
**Last updated:** {YYYY-MM-DD}

### Decisions
| Decision | Rationale |
|----------|-----------|
| Chose X over Y | Because Z |

### Active Blockers
- {blocker, or "None"}

### Next Steps
- {action item 1}
- {action item 2}

### Notes
- {insight or pattern worth remembering}
```

**Rules:**
- Only include subsections the user selected in Step 2
- **Status** and **Last updated** are always present
- Single-line entries, not paragraphs
- Use tables for structured data (decisions with rationale)
- Point to files (`See {filename}`) rather than duplicating content
- Include custom notes from Step 3 under the Notes subsection if provided

### Step 6: Replace the Session Context Section and Stamp Frontmatter

**6a. Replace the section.** If `## Session Context` exists, call `get_section` on it, then `edit_section` in `replace` mode with the returned version and the new body (without the heading). If it does not exist, add the whole section to the end of the note with `append_note`.

**6b. Stamp the date.** Set `last-touched: YYYY-MM-DD` with `update_frontmatter`.

**Critical:** The summary file is manually curated. Touch only the Session Context section and the `last-touched` frontmatter property.

### Step 7: Link to Today's Daily Note (Side Effect)

Build a passive event log of project engagement so backlinks on the project file naturally accumulate "when did I touch this." This step is best-effort and silent on failure, never block the main flow.

**7a. Read today's daily note,** `0_Inbox/YYYY-MM-DD.md` in `{Vault}`, with `read_note`. If it does not exist, **skip silently**. Do NOT create one, that is `start-day`'s job. Some vaults (e.g., work) may not use daily notes.

**7b. Idempotency:** if the daily note already contains `[[{ProjectName}]]`, skip.

**7c. Append:** if `## Sessions` exists, add `- [[{ProjectName}]]` under it with `edit_section` in `append` mode. Otherwise add the section to the end of the note with `append_note`:

```markdown
## Sessions
- [[{ProjectName}]]
```

**7d. Swallow errors.** This is a side effect, not the primary purpose of `/update-project-state`.

### Step 8: Confirm

Output a confirmation:

```
Session Context Updated

Snapshot written to: {Vault} → {ProjectPath}/{ProjectName}.md
- {list of what was added/changed}

Status: {the status line written}
Last updated: {date}
```

---

## Guidelines

- **Context efficiency is paramount.** This section is loaded every session via `/continue-project`
- **Signal over noise.** The "why" matters more than the "what"
- **Point, don't duplicate.** Reference files instead of copying content
- **Respect the existing file.** Match the style already in use; only touch `## Session Context`
- **Replace, don't accumulate.** This section always reflects current state. Historical record lives in Session Logs.

---
context: conversation
description: Preserve session learnings to your project's canonical summary file via Obsidian CLI
model: opus
allowed-tools: Bash, AskUserQuestion
---

# /preserve - Preserve Session Knowledge

Updates the project's canonical summary file with key learnings from this session. Writes a `## Session Context` section that represents current project state — replaced (not accumulated) on each run.

**Independent skill.** Can run alone or before `/compress`. Does not depend on or trigger any other skill.

## Instructions for Claude

### Step 0: Verify Obsidian Is Running

Run a quick check:
```bash
obsidian version
```

If this fails or returns an error, stop and tell the user: "Obsidian doesn't appear to be running. Please open it and try again."

### Step 1: Detect Project Context

1. Get the current working directory via `pwd`
2. Extract the folder name (last path component) — this is the **project name**
3. Determine the vault-relative path of the summary file
4. Verify the summary file exists:
   ```bash
   obsidian read file="{ProjectName}" vault="ObsidianWork"
   ```
5. If not found, ask the user:
   "No summary file `{ProjectName}.md` found in this project folder. Would you like me to create one, or specify a different file?"

If the user provides a vault name override, use that instead of `ObsidianWork` throughout.

### Step 2: Ask What to Preserve

Use AskUserQuestion with multi-select:

**Question:** "What should be preserved from this session?"

**Options:**
1. **Phase/Status Changes** — what moved forward, what's now complete
2. **Key Decisions** — choices made and why (for future reference)
3. **New Files/Structure** — what was created or changed
4. **Patterns/Insights** — reusable learnings, "aha" moments
5. **Blockers/Warnings** — issues for future sessions
6. **Next Steps** — clear action items

### Step 3: Ask for Custom Notes (Optional)

Ask: "Anything specific you want to highlight or remember? (Type 'skip' to continue)"

### Step 4: Read Current Summary File

Read the full content of the summary file:
```bash
obsidian read file="{ProjectName}" vault="ObsidianWork"
```

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

### Step 6: Replace the Session Context Section

**If `## Session Context` already exists in the file:**
1. Parse the file content from Step 4
2. Find the `## Session Context` heading
3. Find the next `## ` heading after it (or end of file)
4. Replace everything between those boundaries with the new section content
5. Write the reconstructed file:
   ```bash
   obsidian create name="{ProjectName}" content="{full reconstructed content}" vault="ObsidianWork" overwrite silent
   ```

**If `## Session Context` does not exist:**
1. Append the new section to the end of the file:
   ```bash
   obsidian append file="{ProjectName}" content="\n\n{session context section}" vault="ObsidianWork"
   ```

**Critical:** Preserve ALL other content in the file exactly as-is. The summary file is manually curated — only touch the Session Context section.

### Step 7: Confirm

Output a confirmation:

```
Session Context Updated

Preserved to: {ProjectName}.md
- {list of what was added/changed}

Status: {the status line written}
Last updated: {date}
```

---

## Guidelines

- **Context efficiency is paramount.** This section is loaded every session via `/resume`
- **Signal over noise.** The "why" matters more than the "what"
- **Point, don't duplicate.** Reference files instead of copying content
- **Respect the existing file.** Match the style already in use; only touch `## Session Context`
- **Replace, don't accumulate.** This section always reflects current state. Historical record lives in Session Logs.

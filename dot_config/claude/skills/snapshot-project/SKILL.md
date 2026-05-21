---
context: conversation
description: Snapshot the project's current state into its canonical summary file via Obsidian CLI
model: opus
allowed-tools: Bash, AskUserQuestion
---

# /snapshot - Snapshot Current Project State

Updates the project's canonical summary file with the current state of understanding. Writes a `## Session Context` section that represents where the project stands now — replaced (not accumulated) on each run.

**Independent skill.** Can run alone or before `/log`. Does not depend on or trigger any other skill.

## Instructions for Claude

### Step 1: Resolve Project Context

This skill operates on a **project** under `1_Projects/` or an **area** under `2_Areas/`. Both must be folder-form: `<category>/<name>/<name>.md`. Other top-level folders (`0_Inbox/`, `3_Resources/`, `4_Archive/`) are not supported.

**1a. Determine the project name:**

- If `$ARGUMENTS` is provided, treat the entire argument string as the project name.
- Otherwise, derive from `pwd`: walk up from cwd. If an ancestor folder is named `1_Projects` or `2_Areas`, the immediate child folder is the project name.
- If neither yields a project, error and stop:
  ```
  No project specified. Run from inside a 1_Projects/ or 2_Areas/ folder, or pass the project name: /snapshot "Project Name"
  ```

**1b. Determine the vault and category:**

- If the walk-up in 1a succeeded, the vault root is the parent of the matched `1_Projects` or `2_Areas` folder. The vault name is that root's basename. The category is whichever of `1_Projects` / `2_Areas` was matched.
- Otherwise (arg-mode from outside any vault):
  1. Run `obsidian vaults verbose` to list vaults and their absolute paths.
  2. For each vault, check whether `<vault path>/1_Projects/<project>/<project>.md` or `<vault path>/2_Areas/<project>/<project>.md` exists on disk.
  3. Exactly one match → use that vault and category.
  4. Multiple matches → error: `"Found '<project>' in multiple vaults: <list>. Run from inside the project folder to disambiguate."`
  5. No match → error: `"No folder-form project or area named '<project>' found in any vault."`

**1c. Set the placeholders used in later steps:**

- `{Vault}` — resolved vault name (e.g., `ObsidianPersonal`, `ObsidianWork`)
- `{Category}` — `1_Projects` or `2_Areas`
- `{ProjectName}` — the project/area name
- `{ProjectPath}` — `{Category}/{ProjectName}` (vault-relative)

**1d. Verify the summary file exists:**

```bash
obsidian read path="{ProjectPath}/{ProjectName}.md" vault="{Vault}"
```

If not found, ask the user:
"No summary file `{ProjectPath}/{ProjectName}.md` found. Would you like me to create one, or specify a different file?"

### Step 2: Ask What to Capture in the Snapshot

Use AskUserQuestion with multi-select:

**Question:** "What should this snapshot capture?"

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
obsidian read path="{ProjectPath}/{ProjectName}.md" vault="{Vault}"
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

### Step 6: Replace the Session Context Section and Stamp Frontmatter

This step performs **one atomic write** that both replaces the Session Context section and stamps the `last-touched` frontmatter property. Never use `obsidian property:set` — it is known to destroy the file body on success.

**6a. Prepare the updated frontmatter:**

Take the frontmatter block from the file read in Step 4. Set (or add) the `last-touched` property to today's date (`YYYY-MM-DD`). Keep all other frontmatter properties exactly as-is.

Example — if the existing frontmatter is:
```
---
tags: [project]
status: active
---
```
Transform it to:
```
---
tags: [project]
status: active
last-touched: 2025-06-01
---
```

**6b. Reconstruct the full file content:**

1. Start with the updated frontmatter from 6a.
2. Take the body (everything after the closing `---`).
   - **If `## Session Context` exists:** find the heading, find the next `## ` heading after it (or end of body), and replace everything between those boundaries with the new section content.
   - **If `## Session Context` does not exist:** append the new section to the end of the body.
3. The result is the complete new file content.

**6c. Write the reconstructed file:**

```bash
obsidian create path="{ProjectPath}/{ProjectName}.md" content="{full reconstructed content}" vault="{Vault}" overwrite silent
```

**6d. Verify the write was not destructive:**

Immediately read the file back:
```bash
obsidian read path="{ProjectPath}/{ProjectName}.md" vault="{Vault}"
```
Confirm that the file body (non-frontmatter content) is present and matches the reconstructed content. If the body is missing or shorter than expected, **stop and report the issue to the user** — do not proceed silently.

**Critical:** Preserve ALL other content in the file exactly as-is. The summary file is manually curated — only touch the Session Context section and the `last-touched` frontmatter property.

### Step 7: Link to Today's Daily Note (Side Effect)

Build a passive event log of project engagement so backlinks on the project file naturally accumulate "when did I touch this." This step is best-effort and silent on failure — never block the main flow.

**7a. Check whether today's daily note exists in `{Vault}`:**

```bash
obsidian daily vault="{Vault}"
```

- If the command errors or indicates no daily note exists, **skip the rest of this step silently**. Do NOT create the daily note — that is `start-day`'s job. Some vaults (e.g., work) may not use daily notes at all.
- If it returns content, capture it.

**7b. Idempotency check:**

If the daily note content already contains the substring `[[{ProjectName}]]` anywhere, skip — the project is already logged for today.

**7c. Append the link:**

If `## Sessions` exists in the daily note, append `- [[{ProjectName}]]` under that heading. Otherwise, append a new `## Sessions` section with the bullet:

```bash
obsidian daily:append vault="{Vault}" content="

## Sessions
- [[{ProjectName}]]"
```

(If `## Sessions` already exists but doesn't contain the project link, append just `- [[{ProjectName}]]` under it via `obsidian daily:append` — the CLI's append behavior controls placement; if precise section insertion isn't possible, appending the bullet to the end of the daily note is acceptable.)

**7d. On any error in this step, swallow it.** This is a side effect, not the primary purpose of `/snapshot`.

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

- **Context efficiency is paramount.** This section is loaded every session via `/resume`
- **Signal over noise.** The "why" matters more than the "what"
- **Point, don't duplicate.** Reference files instead of copying content
- **Respect the existing file.** Match the style already in use; only touch `## Session Context`
- **Replace, don't accumulate.** This section always reflects current state. Historical record lives in Session Logs.

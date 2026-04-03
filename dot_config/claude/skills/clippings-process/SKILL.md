---
name: clippings-process
description: Processes web clippings tagged with #clipping from Obsidian vaults — summarizes each clipping, files it into the appropriate 2_Areas/ subfolder in the personal vault based on tags, and removes the original. Use this skill whenever the user says "process clippings", "sort clippings", "clean up clippings", "organize clippings", mentions their Clippings folder, or asks to organize saved/clipped articles. Also trigger when the user runs /clippings-process.
allowed-tools: Bash, Read, Edit, Glob, Grep, AskUserQuestion
---

Process web clippings into summarized notes filed in the personal vault. All vault interaction goes through the `obsidian` CLI — this avoids reading/writing files on disk directly, which saves tokens and keeps Obsidian's index in sync.

## Context

The user has two Obsidian vaults synced via Syncthing:
- **ObsidianWork** — work vault
- **ObsidianPersonal** — personal vault with PARA structure: `0_Inbox/`, `1_Projects/`, `2_Areas/`, `3_Resources/`, `4_Archive/`

Clippings in the work vault are personal-interest content discovered during work hours, so they always get filed into the **personal vault**.

---

## Step 1 — Discover vaults

Run `obsidian vaults` to confirm both vaults are available. If the personal vault isn't listed, tell the user and stop.

---

## Step 2 — Collect all clippings

Search both vaults for notes tagged `#clipping`. Collect the full list before processing so the user knows the scope upfront.

```bash
obsidian vault:open ObsidianWork
obsidian search query="tag:#clipping"
```

Then switch and search the personal vault:

```bash
obsidian vault:open ObsidianPersonal
obsidian search query="tag:#clipping"
```

Combine results from both vaults into a single list. Tell the user how many clippings were found and list them by title. If none were found, say so and stop.

---

## Step 3 — Process each clipping

Work through the list one at a time. After each clipping, **pause and confirm with the user** before moving on — this lets them course-correct folder choices or summaries as you go.

### 3a — Read the clipping

Switch to the vault the clipping lives in, then read it:

```bash
obsidian vault:open <VaultName>
obsidian read path="<path from search results>"
```

Extract from the YAML frontmatter:
- `title` — article/post title
- `source` — original URL (always preserve)
- `tags` — keep all tags except the generic `clippings`/`clipping` tag
- `author`, `created`, `description` — retain if present

### 3b — Choose a destination folder

Switch to the personal vault and list the `2_Areas/` subfolders:

```bash
obsidian vault:open ObsidianPersonal
obsidian files folder="2_Areas"
```

Parse the output to get the distinct top-level subfolder names under `2_Areas/`.

Match the clipping's tags to the best-fitting folder semantically. Tags won't match folder names exactly — `nutrition` might map to `Health`, `typescript` to `Programming`, etc. Use judgment.

- **Clear match:** use that folder.
- **No good match:** suggest the top 2 candidate folders and offer to create a new one. Ask the user to pick.

### 3c — Summarize and write the note

Build the summary note content. The frontmatter structure:

```markdown
---
tags:
  - tag1
  - tag2
source: <original URL>
author: <if available>
clipped: <original created date>
---

<summary content>

---
*Source: [Original Title](url)*
```

**Summary guidelines** (adapt to content length):
- **Short content** (social posts, brief articles): distill into a clean bulleted list. Get to the point.
- **Long content** (full articles, guides): lead with a 2–3 sentence takeaway, then bulleted details by theme. The user should get 80% of the value from a glance.

Strip filler, self-promotion, and repetitive phrasing. Keep what's actionable or informative.

**File name:** Descriptive, no date prefix, concise but findable. Example: `High Protein Breakfast Recipe` not `3 Minute Breakfast` or `2026-04-02 Nutrition Post`.

Write the note to the personal vault using `obsidian create` with `silent` so it doesn't pop open:

```bash
obsidian vault:open ObsidianPersonal
obsidian create path="2_Areas/<Subfolder>/<File Name>.md" content="<full note content>" silent overwrite
```

For multiline content, use `\n` for newlines and `\t` for tabs in the content string.

### 3d — Confirm and clean up

Show the user:
- Destination folder
- File name
- First few lines of the summary

Ask if it looks good. On confirmation, trash the original clipping:

```bash
obsidian vault:open <OriginalVaultName>
obsidian trash path="<original clipping path>"
```

Move to the next clipping, or tell the user you're done.

---
name: clippings-process
description: Processes web clippings from an Obsidian vault's Clippings/ folder — summarizes each clipping, files it into the appropriate 2_Areas/ subfolder in the personal vault based on tags, and removes the original. Use this skill whenever the user says "process clippings", "sort clippings", "clean up clippings", mentions their Clippings folder, or asks to organize saved/clipped articles. Also trigger when the user runs /clippings-process.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

Process web clippings from an Obsidian vault's `Clippings/` folder into summarized notes filed in the personal vault.

The user has two Obsidian vaults synced via Syncthing, always siblings in the same parent directory:
- **ObsidianWork** — work vault
- **ObsidianPersonal** — personal vault with PARA structure: `0_Inbox/`, `1_Projects/`, `2_Areas/`, `3_Resources/`, `4_Archive/`

Clippings in the work vault are personal-interest content discovered during work hours, so they always get filed into the **personal vault**.

---

## Step 1 — Locate both vaults

Determine which vault you're currently in by checking the working directory for `ObsidianWork` or `ObsidianPersonal` in the path. Then derive the sibling vault path:

```
parent_dir = (parent of current vault directory)
work_vault = parent_dir/ObsidianWork
personal_vault = parent_dir/ObsidianPersonal
```

Verify both paths exist. If the personal vault can't be found, tell the user and stop.

---

## Step 2 — Find clippings to process

Look in `Clippings/` within the **current vault** (whichever one you're in). List all `.md` files there. Ignore non-markdown files (like `.base` files).

If the folder is empty or missing, tell the user there's nothing to process and stop.

---

## Step 3 — Process clippings one at a time

For each clipping file, do Steps 3a through 3e, then **pause and confirm with the user** before moving to the next clipping. This lets them course-correct folder choices or summaries as you go.

### Step 3a — Read and parse the clipping

Read the file. Extract from the YAML frontmatter:
- `title` — the article/post title
- `source` — the original URL (preserve this)
- `tags` — list of tags (drop the generic `clippings` tag, keep the rest)
- `author`, `created`, `description` — retain if present

Read the body content below the frontmatter.

### Step 3b — Match tags to a 2_Areas subfolder

List the existing folders inside `personal_vault/2_Areas/`. Compare the clipping's tags against folder names to find the best semantic match. Tags won't be exact matches — a tag like `nutrition` might map to a folder called `Health` or `Fitness`. Use your judgment on the best fit.

**If a clear match exists:** use that folder.

**If no good match exists:** suggest the top 2 candidate folders that come closest, and also offer to create a new folder. Ask the user which option they prefer. If they pick a new folder, create it.

### Step 3c — Create the summary note

Build a new markdown file with this structure:

```markdown
---
tags:
  - tag1
  - tag2
source: (original URL)
author: (if available)
clipped: (original created date)
---

(Summary content here)

---
*Source: [Original Title](url)*
```

**For the summary content**, use judgment based on length:

- **Short content** (like the example LinkedIn post): distill into a clean bulleted list. Get to the point — the user wants quick-reference notes, not a rehash of the original prose.
- **Long content** (full articles, detailed guides): lead with a 2-3 sentence written summary of the key takeaway, then follow with bulleted details organized by theme or section. The goal is that the user can glance at the summary and get 80% of the value without re-reading the source.

Strip any filler, self-promotion, or repetitive phrasing from the source. Keep what's actionable or informative.

### Step 3d — Write the file

**File name:** Use a descriptive title derived from the content (no date prefix). Keep it concise but specific enough to be findable. Example: `High Protein Breakfast Recipe.md`, not `3 Minute Breakfast.md` or `2026-04-02 Nutrition Post.md`.

Write the file to the matched `2_Areas/` subfolder in the personal vault.

### Step 3e — Confirm and clean up

Show the user:
- Which folder you filed it into
- The file name you chose
- A brief preview of the summary (first few lines)

Ask if it looks good. If they confirm (or don't object), delete the original clipping file from `Clippings/`.

If there are more clippings, move to the next one. Otherwise, tell the user you're done.

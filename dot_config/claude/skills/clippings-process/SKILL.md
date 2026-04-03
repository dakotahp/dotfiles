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

Obsidian provides a CLI named `obsidian` that interfaces with the Obsidian desktop app when it is running. Use it for token efficiency when instructed.

**Important CLI notes:**
- Always structure commands as `obsidian <subcommand> vault=<name> [options]` — vault comes after the subcommand, not before
- `vault:open` is NOT a valid command — do not use it
- Never run `obsidian --help` — it prints help but hangs and never exits

---

## Step 1 — Locate both vaults

Verify which vaults are available with `obsidian vaults`. This will return vault names.

Verify at least the personal vault exists. If the personal vault can't be found, tell the user and stop.

---

## Step 2 — Find clippings to process

List files in the work vault's Clippings folder:

`obsidian files vault=ObsidianWork folder="Clippings"`

After processing the work vault, repeat for the personal vault:

`obsidian files vault=ObsidianPersonal folder="Clippings"`

If both folders are empty or missing, tell the user there's nothing to process and stop.

---

## Step 3 — Process all clippings without interruption

Process every clipping back-to-back. Do **not** pause between clippings to ask for confirmation — read, summarize, file, and delete each one in sequence, then show a summary table at the end. Only stop to ask the user a question if no reasonable folder match exists (see Step 3b).

### Step 3a — Read and parse the clipping

Read the file with `obsidian read vault=ObsidianWork path="<exact path>"` (use `path=` not `file=` for exact paths from the file listing). Extract from the YAML frontmatter:
- `title` — the article/post title
- `source` — the original URL (preserve this)
- `tags` — list of tags (drop the generic `clippings` tag, keep the rest)
- `author`, `created`, `description` — retain if present

Read the body content below the frontmatter.

### Step 3b — Match tags to a 2_Areas subfolder

List the distinct existing folders inside the personal vault's `2_Areas/` with:

`obsidian files vault=ObsidianPersonal folder="2_Areas" | grep -o -E "^/?([^/]+/){1,2}" | uniq`

Compare the clipping's tags against folder names to find the best semantic match. Tags won't be exact matches — a tag like `nutrition` might map to a folder called `Health` or `Fitness`. Use your judgment on the best fit.

**If a clear match exists:** use that folder and continue without asking.

**If no good match exists:** this is the only time to pause and ask the user — suggest the top 2 candidate folders and offer to create a new one. Once answered, continue processing remaining clippings without further interruption.

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

- **Short content** (like a LinkedIn post): distill into a clean bulleted list. Get to the point — the user wants quick-reference notes, not a rehash of the original prose.
- **Long content** (full articles, detailed guides): lead with a 2-3 sentence written summary of the key takeaway, then follow with bulleted details organized by theme or section. The goal is that the user can glance at the summary and get 80% of the value without re-reading the source.

Strip any filler, self-promotion, or repetitive phrasing from the source. Keep what's actionable or informative.

### Step 3d — Write the file

**File name:** Use a descriptive title derived from the content (no date prefix). Keep it concise but specific enough to be findable. Example: `High Protein Breakfast Recipe.md`, not `3 Minute Breakfast.md` or `2026-04-02 Nutrition Post.md`.

Write the file to the matched `2_Areas/` subfolder in the personal vault using:

`obsidian create vault=ObsidianPersonal path="2_Areas/<Subfolder>/<File Name>.md" content="<content>"`

Note: `create` is the correct command — `write` does not exist.

### Step 3e — Delete the original

Immediately delete the original clipping file without asking:

`obsidian delete vault=ObsidianWork path="Clippings/<filename>.md"`

Then move to the next clipping.

---

## Step 4 — Final summary

After all clippings are processed, show the user a table:

| File created | Folder |
|---|---|
| ... | ... |

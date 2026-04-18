---
name: clippings-process
description: Processes web clippings from an Obsidian vault — summarizes each clipping, files it into the appropriate 2_Areas/ subfolder in the personal vault based on tags, and removes the original. Use this skill whenever the user says "process clippings", "sort clippings", "clean up clippings", or asks to organize saved/clipped articles. Also trigger when the user runs /clippings-process.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

Process web clippings from Obsidian vaults into summarized notes filed in the personal vault. Clippings are identified by the `#clippings` tag — they can live anywhere in either vault.

The user has two Obsidian vaults synced via Syncthing, always siblings in the same parent directory:
- **ObsidianWork** — work vault
- **ObsidianPersonal** — personal vault with PARA structure: `0_Inbox/`, `1_Projects/`, `2_Areas/`, `3_Resources/`, `4_Archive/`

Clippings in the work vault are personal-interest content discovered during work hours, so they always get filed into the **personal vault**.

Obsidian provides a CLI named `obsidian` that interfaces with the Obsidian desktop app when it is running.

**Important CLI notes:**
- Always structure commands as `obsidian <subcommand> vault=<name> [options]` — vault comes after the subcommand, not before
- `vault:open` is NOT a valid command — do not use it
- Never run `obsidian --help` — it prints help but hangs and never exits
- The `vault=` parameter does NOT switch vaults — it is effectively ignored. The CLI always targets the active vault in the Obsidian app.

**Vault access strategy:**
- **ObsidianWork** — use filesystem tools only (`ls`, Read tool, `rm`) since the CLI cannot target it. Resolve its path dynamically from `obsidian vaults verbose` (see Step 1).
- **ObsidianPersonal** — use the `obsidian` CLI for all operations (it's the active vault).

---

## Step 1 — Resolve vault paths

Run `obsidian vaults verbose` to get vault names and their filesystem paths:

```bash
obsidian vaults verbose
# Output format: <VaultName>\t<path>
# e.g.:
#   ObsidianWork      /home/user/Syncthing/ObsidianWork
#   ObsidianPersonal  /home/user/Syncthing/ObsidianPersonal
```

Parse and store the ObsidianWork path. Use it for all filesystem operations against that vault. Do not hard-code paths.

If ObsidianWork cannot be found, tell the user and stop.

---

## Step 2 — Find clippings to process

Search for files tagged `#clippings` in the personal vault:

```bash
obsidian search vault=ObsidianPersonal query="tag:#clippings" format=json
```

Search for files tagged `#clippings` in the work vault via filesystem grep:

```bash
grep -rl "clippings" "<work_vault_path>" --include="*.md" | xargs grep -l "tags:" | while read f; do grep -q "clippings" "$f" && echo "$f"; done
```

Or more precisely, look for files where the frontmatter tags list includes `clippings`:

```bash
grep -rl "^\s*-\s*['\"]?clippings['\"]?" "<work_vault_path>" --include="*.md"
```

If no tagged clippings are found in either vault, tell the user there's nothing to process and stop.

---

## Step 3 — Process all clippings without interruption

Process every clipping back-to-back. Do **not** pause between clippings to ask for confirmation — read, summarize, file, and delete each one in sequence, then show a summary table at the end. Only stop to ask the user a question if no reasonable folder match exists (see Step 3b).

### Step 3a — Read and parse the clipping

For **ObsidianWork** clippings, read the file using the Read tool with the full resolved path returned from the grep search.

For **ObsidianPersonal** clippings, read via the CLI using the path returned from the search:

`obsidian read vault=ObsidianPersonal path="<path from search result>"`

Extract from the YAML frontmatter:
- `title` — the article/post title
- `source` — the original URL (preserve this)
- `tags` — list of tags (drop the generic `clippings` tag, keep the rest)
- `author`, `created`, `description` — retain if present

Read the body content below the frontmatter.

### Step 3b — Match tags to a 2_Areas subfolder

List the existing subfolders inside the personal vault's `2_Areas/` via CLI:

```bash
obsidian folders vault=ObsidianPersonal folder="2_Areas"
```

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

(1–2 sentence spark summary)

---

(Detail content here — bullets, sections, etc.)

---
*Source: [Original Title](url)*
```

**The first line after frontmatter is always a 1–2 sentence spark summary**, separated from the detail content by a `---` divider. This block exists solely as a daily teaser — it should stand alone without the rest of the note.

- Aim for 1 sentence; use 2 only if one sentence can't carry the idea
- Write it as a declarative insight, not a description of the article ("Over-apologizing erodes credibility" not "This post is about apologizing at work")
- If the content has a memorable phrase or reframe, lead with that

**The detail content** after the divider is independent — format it however best fits the source:

- **Short content** (like a LinkedIn post): distill into a clean bulleted list. Get to the point — the user wants quick-reference notes, not a rehash of the original prose.
- **Long content** (full articles, detailed guides): bulleted details organized by theme or section. The goal is that the user can glance and get 80% of the value without re-reading the source.

Strip any filler, self-promotion, or repetitive phrasing from the source. Keep what's actionable or informative.

### Step 3d — Write the file

**File name:** Use a descriptive title derived from the content (no date prefix). Keep it concise but specific enough to be findable. Example: `High Protein Breakfast Recipe.md`, not `3 Minute Breakfast.md` or `2026-04-02 Nutrition Post.md`.

Write the file to the matched `2_Areas/` subfolder in the personal vault using the CLI:

`obsidian create vault=ObsidianPersonal path="2_Areas/<Subfolder>/<File Name>.md" content="<content>"`

Note: `create` is the correct command — `write` does not exist.

### Step 3e — Delete the original

Immediately delete the original clipping file without asking.

For **ObsidianWork** clippings:
```bash
rm "<full_path_from_grep_result>"
```

For **ObsidianPersonal** clippings:
```bash
obsidian delete vault=ObsidianPersonal path="<path from search result>"
```

Then move to the next clipping.

---

## Step 4 — Final summary

After all clippings are processed, show the user a table:

| File created | Folder |
|---|---|
| ... | ... |

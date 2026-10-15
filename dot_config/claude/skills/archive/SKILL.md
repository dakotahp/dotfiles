---
name: archive
description: Archive a file (or folder with --folder) to 4_Archive/ by mirroring its source path so the archive stays navigable
allowed-tools: AskUserQuestion, mcp__obsidian-vault
model: haiku
---

Move a file to `4_Archive/`, preserving its full vault-relative path so it stays findable without searching.

**Destination rule:** prepend `4_Archive/` to the file's existing path. That's it.
- `1_Projects/My Project/Some Note.md` → `4_Archive/1_Projects/My Project/Some Note.md`
- `2_Areas/My Area/Old Note.md` → `4_Archive/2_Areas/My Area/Old Note.md`

**Usage:**
- `/archive`: pick from the notes changed most recently
- `/archive "Note Name"`: find and archive a named file
- `/archive --folder "Project Name"`: archive an entire project/area folder

The vaults are `Work` and `Personal`. Set `$VAULT` to the one that holds the target.

---

## Step 1: Determine the target

### Case A: `--folder` flag

If `$ARGUMENTS` starts with `--folder`, strip that flag and treat the remainder as a project/area folder name. Jump to the **Folder Archive** path at the end of this skill.

### Case B: Named file argument

If `$ARGUMENTS` is provided (and does not start with `--folder`), search both vaults with `search_notes`: `query: "$ARGUMENTS"`, `output: files`. Prefer results flagged `title_match`.

If multiple results come back, filter to files under `1_Projects/`, `2_Areas/`, or `3_Resources/` (skip files already under `4_Archive/`). If still ambiguous, present the top matches and ask the user which one. Set `$VAULT` and `$FILE_PATH` to the chosen file's vault and vault-relative path.

### Case C: No argument

The MCP cannot see which note is open in the Obsidian app. Call `recent_notes` with `limit: 5` in both vaults, show the newest few, and ask which one to archive.

If nothing resolves, stop:
```
No file specified. Pass a file name: /archive "Note Name"
```

---

## Step 2: Validate source and compute destination

If the file is already under `4_Archive/`, stop: `File is already archived: $FILE_PATH`

Set `$DEST_PATH` to `4_Archive/$FILE_PATH`.

---

## Step 3: Move (individual file)

Call `move_note` in `$VAULT` with `path: $FILE_PATH`, `new_path: $DEST_PATH` and `update_links: true`, so wikilinks keep pointing at the note.

If it fails because the destination exists, stop: `Destination already exists: $DEST_PATH, aborting.` If the source is missing, stop: `File not found: $FILE_PATH`

---

## Step 4: Confirm

Output one line:
```
Archived: $FILE_PATH → $DEST_PATH
```

No further action needed for individual files. Done.

---

## Folder Archive path (`--folder`)

Used only when the `--folder` flag was passed. Archive an entire project or area folder.

### F1: Locate source folder

From the argument (with `--folder` stripped), set `$NAME`. In both vaults, `list_notes` on `1_Projects/$NAME` and `2_Areas/$NAME`.

If found in more than one place, ask the user which to archive. If none, stop: `No folder "$NAME" found under 1_Projects/ or 2_Areas/.`

Set `$VAULT` and `$CATEGORY`.

### F2: Check for a collision

`list_notes` on `4_Archive/$CATEGORY/$NAME`. If it holds anything, stop: `Destination already exists: 4_Archive/$CATEGORY/$NAME, aborting.`

### F3: Confirm

`list_notes` on `$CATEGORY/$NAME` with `recursive: true`, and count the notes.

Show:
```
Archive folder: $CATEGORY/$NAME
             → 4_Archive/$CATEGORY/$NAME
         Notes: N
```

Ask: "Proceed?" (Yes / No). If No, stop.

### F4: Move folder

Move each note with `move_note` to `4_Archive/<its path>`, with `update_links: true`.

The MCP moves Markdown notes only. Tell the user that attachments, such as images or PDFs, and the empty source folder stay behind for them to move or delete in Obsidian.

### F5: Confirm

The canonical file's `status:` is intentionally **left alone**. The `4_Archive/` folder location is the signal that the project is archived; the existing `status:` (`done`, `paused`, `active`, or absent) preserves the historical record of how the project ended, finished vs. shelved vs. abandoned mid-flight. Queries for active work should filter out anything under `4_Archive/` by path, not by status.

```
Archived: $CATEGORY/$NAME → 4_Archive/$CATEGORY/$NAME
```

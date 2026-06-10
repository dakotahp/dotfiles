---
name: archive
description: Archive a file (or folder with --folder) to 4_Archive/ by mirroring its source path so the archive stays navigable
allowed-tools: Bash, AskUserQuestion
model: haiku
---

Move a file to `4_Archive/`, preserving its full vault-relative path so it stays findable without searching.

**Destination rule:** prepend `4_Archive/` to the file's existing path. That's it.
- `1_Projects/My Project/Some Note.md` → `4_Archive/1_Projects/My Project/Some Note.md`
- `2_Areas/My Area/Old Note.md` → `4_Archive/2_Areas/My Area/Old Note.md`

**Usage:**
- `/archive` — archive the file currently open in the Obsidian app
- `/archive "Note Name"` — find and archive a named file (safer if there's a gap between opening and running)
- `/archive --folder "Project Name"` — archive an entire project/area folder

---

## Step 1: Resolve vault and vault path

```bash
VAULT=$(obsidian vaults | grep -m1 "Obsidian" | awk '{print $1}')
# Default to ObsidianPersonal if detection fails
VAULT_PATH=$(obsidian vault=$VAULT eval code="app.vault.adapter.basePath" | sed 's/^=> //')
```

---

## Step 2: Determine the target

### Case A — `--folder` flag

If `$ARGUMENTS` starts with `--folder`, strip that flag and treat the remainder as a project/area folder name. Jump to the **Folder Archive** path at the end of this skill.

### Case B — Named file argument

If `$ARGUMENTS` is provided (and does not start with `--folder`), search for the file:

```bash
obsidian vault=$VAULT search query="$ARGUMENTS" format=json
```

If multiple results come back, filter to files under `1_Projects/`, `2_Areas/`, or `3_Resources/` (skip files already under `4_Archive/`). If still ambiguous, present the top matches and ask the user which one. Set `$FILE_PATH` to the vault-relative path of the chosen file.

### Case C — Active file (default, no argument)

```bash
obsidian vault=$VAULT eval code="app.workspace.getActiveFile()?.path"
```

Strip the `=> ` prefix. Set `$FILE_PATH` to the returned vault-relative path.

If nothing resolves, stop:
```
No file specified and no active file detected. Run from inside the vault with a file open, or pass a file name.
```

---

## Step 3: Validate source and compute destination

Confirm the file exists:
```bash
test -f "$VAULT_PATH/$FILE_PATH" && echo "found" || echo "missing"
```

If missing, stop: `File not found: $FILE_PATH`

If the file is already under `4_Archive/`, stop: `File is already archived: $FILE_PATH`

**Compute destination:**
```bash
DEST_PATH="4_Archive/$FILE_PATH"
DEST_DIR=$(dirname "$VAULT_PATH/$DEST_PATH")
```

Check for collision:
```bash
test -f "$VAULT_PATH/$DEST_PATH" && echo "exists" || echo "clear"
```

If destination already exists, stop: `Destination already exists: $DEST_PATH — aborting.`

---

## Step 4: Move (individual file)

Create the destination directory and move using the Obsidian CLI so wikilinks are updated:

```bash
mkdir -p "$DEST_DIR"
obsidian vault=$VAULT move path="$FILE_PATH" to="$DEST_PATH"
```

If `obsidian move` fails, fall back to `mv`:
```bash
mv "$VAULT_PATH/$FILE_PATH" "$VAULT_PATH/$DEST_PATH"
```

---

## Step 5: Confirm

Output one line:
```
Archived: $FILE_PATH → $DEST_PATH
```

No further action needed for individual files. Done.

---

---

## Folder Archive path (`--folder`)

Used only when the `--folder` flag was passed. Archive an entire project or area folder.

### F1: Locate source folder

From the argument (with `--folder` stripped), set `$NAME`. Check in parallel:

```bash
test -d "$VAULT_PATH/1_Projects/$NAME" && echo "1_Projects"
test -d "$VAULT_PATH/2_Areas/$NAME"    && echo "2_Areas"
```

If found in both, ask the user which to archive. If neither, stop: `No folder "$NAME" found under 1_Projects/ or 2_Areas/.`

Set `$CATEGORY` and `$SRC_DIR="$VAULT_PATH/$CATEGORY/$NAME"`.

### F2: Compute destination and check collision

```bash
DEST_DIR="$VAULT_PATH/4_Archive/$CATEGORY/$NAME"
test -e "$DEST_DIR" && echo "exists" || echo "clear"
```

If exists, stop: `Destination already exists: 4_Archive/$CATEGORY/$NAME — aborting.`

### F3: Confirm

```bash
find "$SRC_DIR" -name "*.md" | wc -l
```

Show:
```
Archive folder: $CATEGORY/$NAME
             → 4_Archive/$CATEGORY/$NAME
         Files: N markdown files
```

Ask: "Proceed?" (Yes / No). If No, stop.

### F4: Move folder

```bash
mkdir -p "$VAULT_PATH/4_Archive/$CATEGORY"
mv "$SRC_DIR" "$VAULT_PATH/4_Archive/$CATEGORY/$NAME"
```

### F5: Confirm

The canonical file's `status:` is intentionally **left alone**. The `4_Archive/` folder location is the signal that the project is archived; the existing `status:` (`done`, `paused`, `active`, or absent) preserves the historical record of how the project ended — finished vs. shelved vs. abandoned mid-flight. Queries for active work should filter out anything under `4_Archive/` by path, not by status.

```
Archived: $CATEGORY/$NAME → 4_Archive/$CATEGORY/$NAME
```

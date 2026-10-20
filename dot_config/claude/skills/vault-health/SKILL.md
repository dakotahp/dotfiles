---
name: vault-health
description: Vault maintenance skill. Auto-fixes inspiration notes missing a summary: field, reports dead wikilinks and orphan notes, suggests tags that connect under-tagged notes across related folders, and suggests merges for tags used only once. Pass "tags <folder> [<folder> ...]" to run only the tag step on a group of related folders. Run periodically to keep the vault tidy and discoverable.
allowed-tools: AskUserQuestion, mcp__obsidian-vault, mcp__claude_ai_Obsidian_Cloud_Vault_Crystal_Cove
---

Vault health check. Use the obsidian-vault MCP for every read and write. It works the same locally and in the cloud, so the skill needs no file access.

**Modes:**

- `/vault-health`: all phases. The tag step picks the 20 notes with the most to gain from across `1_Projects/`, `2_Areas/` and `3_Resources/`.
- `/vault-health tags <folder> [<folder> ...]`: only the tag step, on every candidate in the named folders. Treat the folders as one cluster of related notes, for example `2_Areas/Career 2_Areas/Leadership 2_Areas/Management`.

**Setup:** call `list_vaults`. If there is more than one vault, use the one whose name matches the current directory; ask if that is unclear.

If a parameter named below is missing from the tool schema, the client holds an old tool list. Reconnect the MCP server, and do not work around it.

---

## Phase 1: Auto-fixes

### 1a: Inspiration notes missing `summary:`

1. `find_notes` with `tags: ["inspiration"]`, `missing_key: "summary"` and `limit: 1000`. Skip `Idea - *.md` notes, which belong to the owner.
2. `read_notes` in batches of 20.
3. For each, write a 1-sentence declarative insight. Follow `Vault Conventions ## The summary: Field`: insight, not description, and lead with a memorable phrase if the note has one.
4. Write it with `update_frontmatter` and `set: {summary: "..."}`.

---

## Phase 2: Reports and suggestions

2a and 2b are independent; run them in parallel.

### 2a: Dead wikilinks

Call `unresolved_links` with `limit: 1000`, and page with `next_offset`. Then sort the results into three groups. Report only the third in full:

- **Daily-note navigation:** a date-named note linking to a date-named target (`YYYY-MM-DD` or `YYYY-WW`). Report only the count.
- **Placeholders:** targets in templates, conventions or skill docs that are clearly examples (`YYYY-MM-DD`, `File name`, `Note title`, `<!-- ... -->`). Drop these.
- **Real dead links:** everything else. Put links outside `4_Archive/` first. Inside `4_Archive/`, group the rows by target and show a count when one target is broken many times.

For each real dead link, look for the likely new target: a note whose name shares the link's main words, often a rename such as `X` → `X (done)` or a shortened title. Use `list_notes` on the source folder or `search_notes`, and put any match in a "Likely fix" column.

### 2b: Orphan notes

Call `orphans` with `unlinked: true` and `exclude_folders: ["4_Archive"]`. Page as needed. Leave out daily and weekly notes. Group the rest by folder:

- `Session Logs/` folders: report the count only. Nothing is meant to link to them.
- Folders with a `.base` file: report the count only, since the base view lists those notes.
- All others: list the paths when a folder has 10 or fewer, otherwise give the count and 3 examples.

### 2c: Tag suggestions

The goal is a mesh: notes that share tags across folders. One more tag that already sits on other notes is worth more than a new tag that sits on one note.

**Operational tags** are the ones in the "Special operational tags" table in `Vault Conventions`, such as `agent-work`, `inspiration`, `idea`, `stub`, `takeaways`, `weekly-note` and `daily-note`. They do not count as topical tags.

**Step 1: Find candidates.** Call `find_notes` with `frontmatter_key: "tags"`, `folders: FOLDERS`, `max_tags: 5` and `limit: 1000`. FOLDERS is the folders from `tags` mode, or `["1_Projects", "2_Areas", "3_Resources"]` in the default mode. `frontmatter_key: "tags"` returns every note with a `tags` field, empty ones included. That leaves out notes with no frontmatter, which are almost always imports, drafts or raw text (cover letters, an imported Bible), and not worth tagging. `max_tags` counts every tag, operational ones included, so it is set above the topical limit.

From the results, drop `Session Logs/` notes, `Idea - *.md` notes, and notes with 4 or more topical tags. Sort by fewest topical tags. In the default mode, keep the first 30, so that 20 remain after Step 3. In `tags` mode, keep all of them.

**Step 2: Load the vocabulary.** Call `list_tags` with `limit: 1000`. Tags used on 2 or more notes are the preferred vocabulary.

**Step 3: Read the candidates.** Use `read_notes` in batches of 20 with `max_chars: 1500`. Drop agent-context notes and notes whose body is under 300 characters (`total_characters` includes the frontmatter). Note each one's main topics.

**Step 4: Find cross-cutting themes first (tags mode).** Before you tag single notes, list the themes that appear in 2 or more of the named folders, for example confidence, meetings, networking, prioritization or decision-making. Give each theme one tag, preferably an existing one, and apply it to every note that is about that theme. Consistent cross-folder tags make the mesh.

**Step 5: Suggest tags for each note.** Rules:

- Bring each note to at most 4 topical tags.
- Sources, in order of preference:
  1. Tags on related notes: folder siblings, the other folders in the cluster, and the note's links. Links are sparse in clipped notes, so siblings and shared themes usually matter more.
  2. Existing vault tags on 2 or more notes.
  3. A new tag, only when it fits 2 or more notes in this run.
- Do not add the name of the note's own folder (no `leadership` for a note in `Leadership/`). Do add a sibling folder's topic when the note is about it, such as `communication` on a Leadership note; that is mesh, not echo.
- Follow vault conventions: singular nouns, kebab-case.
- Do not suggest a project's own name as a tag inside that project's folder.
- Never remove tags in this step; only add.

**Step 6: Suggest merges for singleton tags.** From `list_tags`, take the tags used on exactly 1 note. Suggest a merge when a singleton means the same thing as another tag, such as `goals` and `goal-setting`, or `books` and `book-notes`. Merge into the clearer, more specific name, which is often the longer one, not just the one used more. Leave alone the singletons with no close match.

---

## Phase 3: Output

```
## Vault Health Report: YYYY-MM-DD

### Auto-fixed
- Inspiration notes missing summary: N fixed (list filenames), or "None needed"

### Dead Wikilinks
- N daily-note navigation links (count only)
(table: File | Broken link | Likely fix), or "None found"

### Orphan Notes
(grouped by folder, counts for expected groups), or "None found"

### Tag Suggestions
- Cross-cutting themes: theme → tag → number of notes
(table: Note | Current | Add | Why)

### Tag Merges
(table: Singleton | Merge into | Note)
```

Keep it skimmable. In `tags` mode, print only the Tag Suggestions and Tag Merges sections. Flag systematic issues, for example "most orphans are clipped notes in 2_Areas/Leadership; tags will connect them more than links".

---

## Phase 4: Apply on approval

After the report, ask once whether to apply the tag suggestions and merges. The owner may answer "apply", "apply except ...", or "skip". Do not write tags before that answer.

- **Add tags:** `update_frontmatter` with `add_tags: [...]`, one call per note, issued in parallel. It merges safely with tags that sync may have added. Never build a full list and `set` it.
- **Merge:** `find_notes` with `tags: [singleton]`, then `update_frontmatter` with `add_tags: [target]` and `remove_tags: [singleton]` on each note. `remove_tags` changes only the frontmatter list. So also run `search_notes` with `query: "#singleton"` and `mode: "phrase"`, and fix any inline hashtag in the body with `edit_note`.
- Then call `list_tags` again and report the change in tag count and any write that failed.

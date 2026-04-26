---
name: refresh-context
description: Audits agent-context files (vault/project/area scope) for staleness and prompts you to refresh them. Two modes — sweep all files via multi-select of the stalest, or refresh a single named file. Updates `last-reviewed` frontmatter after each file is confirmed accurate or edited.
allowed-tools: Bash, Read, Edit, Write, AskUserQuestion
---

Agent-context files (frontmatter `agent-context: vault | project | area`) are loaded automatically by start-day, end-week, and per-folder sessions. They drift silently — Life Domains, project Index.md, area files — and that drift miscalibrates every downstream agent decision. This skill makes the drift visible and easy to fix.

Vault: ObsidianPersonal. All obsidian commands use `vault=ObsidianPersonal` immediately after the subcommand.

---

## Mode selection

If the user passed a filename or partial path as an argument, run **single-file mode**.
If no argument, run **sweep mode**.

---

## Sweep mode

### Step 1 — Inventory

```bash
obsidian vault=ObsidianPersonal search query="[agent-context]" format=json
```

For each returned path, read the frontmatter and capture two fields:
- `agent-context` (vault/project/area)
- `last-reviewed` (YYYY-MM-DD, or absent)

Compute staleness in days:
- If `last-reviewed` is present: `(today - last-reviewed)`
- If absent: treat as **never reviewed** — sort to top of the list

### Step 2 — Build the multi-select

Sort all files by staleness descending. Cap at 8 candidates (the stalest). For each, build:

- **label**: `<scope>: <filename>` — e.g. `vault: Life Domains` or `project: Chemo Navigator/Index`
- **description**: one line — `Last reviewed N days ago` or `Never reviewed`. If `agent-context: vault`, append a brief note that this file shapes every session's framing (higher leverage to keep current).

Present via `AskUserQuestion` with `multiSelect: true`:
- header: short, e.g. "Stale agent-context files"
- question: "Which agent-context files should I walk through with you to refresh?"

If the user selects zero, exit cleanly with a one-line note ("No files refreshed.").

### Step 3 — Walk each selected file

For each selected file, do this in sequence (do not parallelize — the user is curating):

1. Read the file in full
2. Output a brief summary to the user:
   - Scope (vault/project/area)
   - Last-reviewed date (or "never")
   - 3-6 bullet points covering the key claims/state the file currently asserts (life domains it lists, current project phase, named priorities, etc.)
3. Ask the user (free-form, NOT AskUserQuestion — the response is open-ended):
   > "What's stale, missing, or no longer load-bearing here? Reply with edits, or 'accurate' to just bump the review date."
4. Based on the response:
   - **"accurate" / "no changes" / similar:** update only `last-reviewed: <today>` in frontmatter
   - **Edits provided:** apply them via `Edit` tool, then update `last-reviewed: <today>`
   - **User says to remove the file or convert it out of agent-context:** confirm once, then either delete via `obsidian` CLI or strip the `agent-context` frontmatter property (do NOT delete the file content unless explicitly told to)
5. Confirm what was done in one line, then move to the next file

### Step 4 — Wrap

After all selected files are processed, output a 2-3 line summary: which files were edited, which were just date-bumped, which were removed from agent-context.

---

## Single-file mode

User invoked with a filename argument (e.g. `/refresh-context Life Domains` or a path).

1. Resolve the file:
   ```bash
   obsidian vault=ObsidianPersonal search query="<arg>" format=json
   ```
   If multiple matches, ask the user which one (AskUserQuestion, single-select). If zero matches, report and exit.

2. Verify it has `agent-context` frontmatter. If not, warn the user — this file is not auto-loaded, so refreshing it has no agent-side effect. Ask if they still want to proceed (single y/n via AskUserQuestion).

3. Run **steps 3 and 4 from sweep mode** for just this one file.

---

## The `last-reviewed` field

This skill writes `last-reviewed: YYYY-MM-DD` to the frontmatter of every agent-context file it touches. The field is the canonical staleness signal — `mtime` is unreliable (any unrelated edit, including Syncthing roundtrips, resets it).

When editing frontmatter, preserve all other fields and ordering. Add `last-reviewed` at the bottom of the frontmatter block if it's not already present.

If a file's frontmatter is malformed (no closing `---`), report it to the user instead of writing — don't risk corrupting it.

---

## Edge cases

- **No `agent-context` files found:** report and exit. Something is wrong with the vault or the search.
- **All files reviewed within last 14 days:** still show the multi-select, but mention in the question body that nothing is obviously stale — the user may still want to spot-check.
- **File listed has been deleted between search and read:** skip with a one-line note, continue with the rest.

---

## Done

Refreshed files now carry an honest `last-reviewed` date. end-week's stale-context check (60+ day threshold) will flag the rest naturally over time.

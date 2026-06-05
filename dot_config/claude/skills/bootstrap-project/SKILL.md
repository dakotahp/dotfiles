---
context: conversation
description: Bootstrap a new project (under 1_Projects/) or area (under 2_Areas/) in an Obsidian vault. Creates the folder and canonical summary file with frontmatter and a one-paragraph intent so agents and future-you have something identifiable to work from. Pass the name as a string; add "area" as a second arg to create an area instead of a project.
model: opus
allowed-tools: Bash, AskUserQuestion, Read
---

# /bootstrap-project - Initialize a Project or Area

Creates the standard folder + canonical summary file for a new project (default) or area, populated with frontmatter and a short stated intent. Designed to be fast: one or two questions, then the file exists and is ready to grow.

## Instructions for Claude

### Step 1: Parse Arguments

`$ARGUMENTS` is the full argument string. Conventions:

- The **last whitespace-separated token** is `area` (case-insensitive) → category is `2_Areas`, and the name is everything before that token.
- Otherwise → category is `1_Projects`, and the name is the entire argument string.
- The name may be wrapped in quotes — strip surrounding `"` or `'`.
- If `$ARGUMENTS` is empty, ask the user for the name and whether it's a project or area (AskUserQuestion).

Set placeholders:

- `{Category}` — `1_Projects` or `2_Areas`
- `{Kind}` — `project` or `area` (matches `{Category}`)
- `{Name}` — the cleaned name (e.g. `Refactor Back-end Architecture`)

### Step 2: Resolve Vault

- Walk up from `pwd`. If an ancestor folder contains an `.obsidian/` directory, that ancestor is the vault root. The vault name is its basename.
- If walk-up fails: run `obsidian vaults` to list vaults.
  - One vault → use it.
  - Multiple → ask the user via AskUserQuestion which vault.

Set `{Vault}`.

### Step 3: Check for Collision

Verify the folder does not already exist:

```bash
obsidian read path="{Category}/{Name}/{Name}.md" vault="{Vault}"
```

- If the file exists, stop and tell the user: `"A {Kind} named '{Name}' already exists at {Category}/{Name}/{Name}.md. Aborting — open it directly or pick a different name."`
- A "not found" error is the expected case; proceed.

### Step 4: Ask for the Intent

Use AskUserQuestion to ask **one** open-ended question:

> "What's the basic intent of this {Kind}? (1-3 sentences — what is it, why does it exist, what would 'done' or 'healthy' look like. You'll flesh this out later in Obsidian; this just gives the file an identifiable starting point.)"

Provide the user options like:
- **Write it now** — user types a short paragraph
- **Skip** — file is created with a placeholder line the user can fill in later

If the user picks "Skip" or types nothing, use this placeholder body:

```
_Intent not yet captured. Fill this in soon so future sessions (and agents) have context to work from._
```

### Step 5: Compose the File

Today's date is `{Today}` (`YYYY-MM-DD`). Build the file content:

```markdown
---
agent-context: {Kind}
status: draft
last-reviewed: {Today}
last-touched: {Today}
---

{Intent paragraph from Step 4 OR the placeholder}
```

Notes:
- `agent-context` value is literally `project` or `area` (matches `{Kind}`).
- Do not add tags, sections, or scaffolding beyond what's above — the user will grow the file organically.

### Step 6: Create the File

```bash
obsidian create path="{Category}/{Name}/{Name}.md" content="{file content}" vault="{Vault}"
```

The `obsidian create` command creates parent folders as needed. Do not pass `overwrite` — collisions were checked in Step 3 and we don't want to clobber.

### Step 7: Verify and Confirm

Read the file back to confirm it was written:

```bash
obsidian read path="{Category}/{Name}/{Name}.md" vault="{Vault}"
```

If the read succeeds, output:

```
Bootstrapped {Kind}: {Name}

Vault:     {Vault}
Location:  {Category}/{Name}/{Name}.md
Intent:    {first ~80 chars of intent, or "(placeholder — fill in soon)"}

Next: open it in Obsidian and start adding context. Use /snapshot later to capture session state.
```

If the read fails, surface the error and stop — don't claim success.

---

## Guidelines

- **Fast path matters.** This skill is supposed to be 1-2 questions and done. Don't expand the file scaffolding or ask follow-up questions beyond intent.
- **Folder-form only.** Always `{Category}/{Name}/{Name}.md` — matches the convention `/snapshot` and `/continue-project` expect.
- **Don't touch daily notes or anything else.** Bootstrap is creation-only; engagement logging happens in `/snapshot`.
- **Be conservative with the body.** A blank-ish file with an honest placeholder is better than fake structure (empty "Decisions" / "Next Steps" tables) that the user will have to delete.

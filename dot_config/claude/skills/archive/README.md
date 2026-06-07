# /archive

A Claude Code skill for archiving notes in an [Obsidian](https://obsidian.md) vault.

## What it does

Moves a note (or an entire project folder) into `4_Archive/` while preserving its original folder structure. So a file at `1_Projects/My Project/Some Note.md` ends up at `4_Archive/1_Projects/My Project/Some Note.md` rather than dumped loose at the archive root.

## Usage

```
/archive                     # archives the file currently open in Obsidian
/archive "Note Name"         # archives a file by name
/archive --folder "Project"  # archives an entire project folder
```

## Why this exists

Obsidian makes it easy to move a whole folder with a right-click, but archiving individual sub-notes is tedious — you have to decide where they go, create subfolders manually, and maintain some organization over time. This skill handles the destination logic automatically so the archive stays navigable without any extra thought.

## Context

This vault uses the [PARA method](https://fortelabs.com/blog/para/) (Projects, Areas, Resources, Archive). The skill mirrors that structure inside `4_Archive/` so archived content is findable by browsing, not just by search.

When archiving a whole project folder, the skill also updates the project's `status` frontmatter property to `archived`.

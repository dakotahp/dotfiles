# /log

Saves a structured session log to your project's `Session Logs/` folder.

## What it does

Creates a dated, keyword-tagged markdown file capturing the important parts of a session — decisions, learnings, solutions, files changed, pending tasks. No raw conversation transcript; only structured, extracted insights.

Files are saved as `Session Logs/YYYY-MM-DD-HH_MM-topic-name.md` within the project folder. The YYYY-MM-DD prefix means files sort chronologically in both the filesystem and Obsidian.

## When to use

- At the end of a working session to capture what happened
- After a significant milestone or decision point
- Whenever you want a searchable historical record of the work

## How it works

1. Asks what to capture (multi-select: learnings, solutions, decisions, files modified, etc.)
2. Optionally takes custom notes
3. Suggests a topic name based on the conversation (you can override)
4. Extracts keywords for future search via `/resume`
5. Generates structured session log content
6. Saves to `Session Logs/` via Obsidian CLI

## Requirements

- Obsidian desktop app must be running
- Working directory must be inside a project folder
- Default vault: `ObsidianWork`

## Relationship to other skills

- **Independent** — can run alone or after `/snapshot`
- `/resume` reads these session logs to restore context in future sessions
- `/snapshot` updates the summary file's current state; `/log` creates historical records

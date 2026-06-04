# /log-project-session

Saves a structured session log to a project's (`1_Projects/<name>/`) or area's (`2_Areas/<name>/`) `Session Logs/` folder. Captures **events** (what happened in a session). For **state** (where the project is now), use `/update-project-state`.

## What it does

Creates a dated, keyword-tagged markdown file capturing the important parts of a session — decisions, learnings, solutions, files changed, pending tasks. No raw conversation transcript; only structured, extracted insights.

Files are saved as `Session Logs/YYYY-MM-DD-HH_MM-topic-name.md` within the project or area folder. The YYYY-MM-DD prefix means files sort chronologically in both the filesystem and Obsidian.

## When to use

- At the end of a working session to capture what happened
- After a significant milestone or decision point
- Whenever you want a searchable historical record of the work

## How it works

1. Asks what to capture (multi-select: learnings, solutions, decisions, files modified, etc.)
2. Optionally takes custom notes
3. Suggests a topic name based on the conversation (you can override)
4. Extracts keywords for future search via `/continue-project`
5. Generates structured session log content
6. Saves to `Session Logs/` via Obsidian CLI

## Requirements

- Obsidian desktop app must be running
- Working directory must be inside a project (`1_Projects/<name>/`) or area (`2_Areas/<name>/`) folder, or pass the name as an argument (e.g. `/log-project-session "Resume Items"`)
- Default vault: `ObsidianWork`

## Relationship to other skills

- **Independent.** Can run alone or alongside `/update-project-state`
- `/continue-project` reads these session logs to restore context in future sessions
- `/update-project-state` writes state (where the project is now); `/log-project-session` writes events (what happened in a session). State vs events

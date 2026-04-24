# /resume

Loads project context and recent session history at the start of a new session.

## What it does

Reads the project's canonical summary file and recent session logs, then outputs a combined report showing where you left off — project state, recent decisions, pending tasks, and suggested next steps.

Supports loading a configurable number of recent sessions and searching past sessions by topic keyword.

## Usage

```
/resume              # summary file + last 3 session logs
/resume 5            # summary file + last 5 session logs
/resume auth         # summary file + last 3 + search for "auth"
/resume 10 migration # summary file + last 10 + search for "migration"
```

## When to use

- At the start of every session in a project folder
- When returning to a project after time away
- When you need to find past sessions related to a specific topic

## How it works

1. Detects the project from the current working directory
2. Reads the summary file (including `## Session Context` if present)
3. Lists and reads recent session logs from `Session Logs/`
4. Optionally searches for topic-matched sessions via Obsidian search
5. Outputs a formatted report with project context, recent sessions, and next steps

## Requirements

- Obsidian desktop app must be running
- Working directory must be inside a project folder with a matching summary file
- Default vault: `ObsidianWork`

## Relationship to other skills

- **Independent** — reads what `/preserve` and `/compress` write
- Reads the `## Session Context` section written by `/preserve`
- Reads session log files created by `/compress`
- Works without either — gracefully handles missing session context or logs

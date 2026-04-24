# /preserve

Updates your project's canonical summary file with key learnings from the current session.

## What it does

Writes (or replaces) a `## Session Context` section in the project's summary file — the markdown file that matches the folder name (e.g., `Feature Seed Data.md` inside `1_Projects/Feature Seed Data/`). This section captures current status, decisions, blockers, and next steps in a lean format.

Each run **replaces** the previous Session Context section rather than accumulating entries. The historical record lives in Session Logs (see `/compress`).

## When to use

- Mid-session when you want to snapshot the current project state
- Before ending a session to capture what changed
- Anytime you want the summary file to reflect the latest context

## How it works

1. Detects the project from the current working directory
2. Asks what to preserve (multi-select: status changes, decisions, blockers, next steps, etc.)
3. Optionally takes custom notes
4. Reads the existing summary file
5. Generates and writes/replaces the `## Session Context` section via Obsidian CLI

## Requirements

- Obsidian desktop app must be running
- Working directory must be inside a project folder with a matching summary file
- Default vault: `ObsidianWork`

## Relationship to other skills

- **Independent** — can run alone or before `/compress`
- `/resume` reads the Session Context section this skill writes
- `/compress` captures a more detailed historical session record in `Session Logs/`

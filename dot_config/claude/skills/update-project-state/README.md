# /update-project-state

Updates your project's canonical summary file with the current state of the project.

## What it does

Writes (or replaces) a `## Session Context` section in the project's summary file (the markdown file that matches the folder name, e.g., `Feature Seed Data.md` inside `1_Projects/Feature Seed Data/`). This section captures current status, decisions, blockers, and next steps in a lean format.

Each run **replaces** the previous Session Context section rather than accumulating entries. This captures **state** (where the project is *now*). For **events** (what happened in a specific session), use `/log-project-session`.

## When to use

- The phase, blockers, kill criteria, or active workstreams have shifted
- Before ending a session if the project state changed during it
- Anytime the answer to "where am I on this project?" has changed since the last run

Not every working session needs a state update. Many sessions will log via `/log-project-session` without changing state.

## How it works

1. Detects the project from the current working directory (or accepts an explicit project name argument)
2. Asks what to preserve (multi-select: status changes, decisions, blockers, next steps, etc.)
3. Optionally takes custom notes
4. Reads the existing summary file
5. Replaces the `## Session Context` section via an atomic read-modify-write
6. Updates `last-touched` frontmatter on the canonical file
7. Appends a `- [[Project]]` bullet to today's daily note under `## Sessions` (side effect)

## Requirements

- Obsidian desktop app must be running
- Working directory must be inside a project folder with a matching summary file, or pass the name as argument

## Relationship to other skills

- **Independent.** Can run alone or alongside `/log-project-session`
- `/continue-project` reads the Session Context section this skill writes
- `/log-project-session` captures historical per-session events in `Session Logs/`. State vs events: this skill writes state, `/log-project-session` writes events

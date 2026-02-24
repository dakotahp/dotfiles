---
name: onboard
description: Analyzes any repository and produces a structured onboarding overview — tech stack, architecture, entry points, conventions, and how to run/test/contribute. Pass a specific area to focus on (e.g. /onboard authentication), or nothing for a full overview.
allowed-tools: Read, Glob, Grep, Bash, Task
---

Analyze this repository and produce a clear onboarding summary for a developer who is new to it.

If $ARGUMENTS is provided, keep the full overview but add a dedicated deep-dive section on that specific area, module, or concept.

Work through the following steps in order, then present everything as a single structured report at the end. Do not print intermediate findings — collect everything first, then output the final report.

---

## Step 1 — Orientation

Read the following files if they exist:
- `README.md` / `README`
- `CLAUDE.md`
- `CONTRIBUTING.md`
- `docs/` — any top-level docs files
- `.github/` — PR templates, issue templates, workflows

Note the project's stated purpose, any setup instructions, and any explicit conventions the authors document.

---

## Step 2 — Tech stack

Identify the languages, frameworks, and runtimes in use by checking:
- `package.json`, `package-lock.json`, `yarn.lock`, `bun.lockb`
- `pyproject.toml`, `requirements.txt`, `Pipfile`
- `Cargo.toml`
- `go.mod`
- `Gemfile`
- `build.gradle`, `pom.xml`
- Any `.tool-versions`, `.nvmrc`, `.ruby-version`, `.python-version`

List the primary language, runtime version, key frameworks, and notable dependencies (separate dev from production where relevant).

---

## Step 3 — Project structure

Map the top two levels of the directory tree. For each significant directory, infer its purpose from its name and contents. Flag anything non-obvious.

Pay particular attention to:
- Where source code lives vs. tests vs. config vs. scripts
- Any monorepo structure (workspaces, packages, apps, libs directories)
- Generated directories that should be ignored

---

## Step 4 — Entry points and core modules

Find where execution begins:
- `main.*`, `index.*`, `app.*`, `server.*`, `cli.*`
- Scripts referenced in `package.json` `scripts`, `Makefile` targets, or `Procfile`
- Dockerfile `CMD` / `ENTRYPOINT`

Identify the 3–6 most central modules or files — the ones a new developer would need to understand first to make sense of the codebase.

---

## Step 5 — Architecture and patterns

Spawn an Explore sub-agent to read a representative sample of source files (aim for breadth over depth) and identify:
- Architectural style (MVC, layered, event-driven, microservices, etc.)
- Key design patterns in use
- How the codebase is organized at a high level (by feature, by layer, by domain, etc.)
- Any notable conventions (naming, file structure, module boundaries)
- Anything that might surprise an experienced developer coming from a different codebase

---

## Step 6 — Data and state

Look for:
- Database setup (`schema.*`, `migrations/`, `prisma/`, `models/`, ORM config)
- State management patterns (Redux, Zustand, context, stores, etc.)
- External services or APIs the project depends on
- Environment variables — check `.env.example`, `.env.sample`, or any documented env vars

---

## Step 7 — Testing

Find the testing setup:
- Test runner and framework (Jest, Vitest, pytest, RSpec, etc.)
- Where tests live and how they're named
- How to run tests (command from package.json, Makefile, etc.)
- Presence of unit, integration, and/or e2e tests
- Any notable testing conventions or helpers

---

## Step 8 — Dev workflow

Determine how to get the project running locally:
- Install command
- Environment setup steps
- Dev server / watch command
- Build command
- Any required services (Docker, databases, etc.)

Check for CI/CD config (`.github/workflows/`, `.circleci/`, `Jenkinsfile`, etc.) and note what runs on PRs and merges.

---

## Step 9 — Focused deep-dive (if $ARGUMENTS provided)

If $ARGUMENTS was provided, explore that specific area in depth:
- Find all files directly related to it
- Trace the key code paths
- Note how it connects to the rest of the system
- Flag anything complex or worth discussing with the team

Skip this step if $ARGUMENTS is empty.

---

## Final report

Present the findings as a clean, well-structured markdown report using this layout:

```
# Onboarding: <repo name>

## What it is
<1–3 sentence plain-English description>

## Tech stack
<language, runtime, key frameworks, notable deps>

## Project structure
<annotated directory tree, top 2 levels>

## How to run it
<install → env setup → dev server, in that order>

## How to test it
<test command, framework, where tests live>

## Architecture
<style, key patterns, how things are organized>

## Core files to read first
<3–6 files with a one-line explanation of each>

## Data and state
<database, state management, key env vars>

## CI/CD
<what runs and when>

## Gotchas and non-obvious things
<anything that would trip up a new developer>

## <Focused deep-dive title> (if applicable)
<deep-dive content>
```

Keep each section concise. Prefer bullet points over prose. The goal is a reference a developer can scan in five minutes and return to as they explore the codebase.

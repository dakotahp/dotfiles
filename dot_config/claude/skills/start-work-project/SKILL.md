---
name: start-work-project
description: Starts a work project from a Linear project. Creates the project's folder in the ObsidianWork vault, links it to Linear, picks a session color, writes a brief with open questions, and names this session as the project's planner. Use at the start of a Linear project, before /technical-plan and /technical-requirements-document, or when the user runs /start-work-project.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, mcp__linear-server__get_project, mcp__linear-server__list_issues, mcp__linear-server__get_issue, mcp__linear-server__list_documents, mcp__linear-server__get_document, mcp__linear-server__list_milestones, mcp__linear-server__list_projects
---

Start the work project for the Linear project in $ARGUMENTS (a URL, ID, or name).

The vault project folder is my private home for this project. Linear stays the team-facing record: published plans, TRDs, and tickets. The vault holds what only serves me: plan drafts before I publish them, session names, the project color, and later a record of my contribution. Never write vault paths, session names, or the color into Linear.

## Where things live

- Vault: `~/Syncthing/ObsidianWork` (the ObsidianWork vault). Projects are `1_Projects/<Name>/`. Archived projects are `4_Archive/1_Projects/<Name>/`.
- The vault is outside the sandbox write list, so vault writes need the sandbox off. Reads work inside it.
- `claude-vault-context --find <ticket ID or Linear project ID>` prints a project folder, or exits 1.

## Step 1: Read the Linear project

Fetch the project, its documents, milestones, and tickets. If $ARGUMENTS is a name with more than one match, ask which one.

## Step 2: Check for an existing folder

Run `claude-vault-context --find <Linear project ID>`. If it finds a folder, stop and suggest `/continue-project "<Name>"`.

The folder name is the Linear project name, minus characters a file name cannot hold. If `1_Projects/<Name>/<Name>.md` exists without `linear-project-id`, ask before adding the Linear fields to it. Keep its body.

## Step 3: Pick a color

Palette, in tie-break order: `purple`, `blue`, `green`, `orange`, `pink`, `cyan`, `yellow`, `red`.

Count the `color:` values in each `1_Projects/*/<Name>.md` (2 points each) and each `4_Archive/1_Projects/*/<Name>.md` (1 point each). Pick the color with the lowest score.

## Step 4: Write the main file

Create `1_Projects/<Name>/<Name>.md`:

```markdown
---
agent-context: project
status: draft
last-reviewed: YYYY-MM-DD
last-touched: YYYY-MM-DD
linear-project-id: <id>
linear-project-url: <url>
color: <color>
planner-session: "proj: <Name>"
tickets: [<existing ticket IDs, or empty>]
---

# <Name>

<One paragraph: what the project delivers and why, in my words, not the Linear description pasted.>

## Brief

**Goal:** <the outcome, in one or two sentences>
**Scope:** <what is in, and what is clearly out>
**Linear documents:** <title and URL per existing document, or "none">

### Open questions

- [ ] <each thing I need to clarify before planning, with who can answer it>

## Session Context

**Status:** Starting. Brief written, open questions pending.
**Last updated:** YYYY-MM-DD

## Sessions

- YYYY-MM-DD · planning · proj: <Name>
```

Write `tickets:` as an inline list, for example `tickets: [APP-101, APP-102]`. Other skills add to it.

Ground the brief in the Linear text and, when the repo is at hand, the code. An open question is something I must answer or ask someone. Do not list questions the code answers; answer them.

## Step 5: Hand off

Print:

```
Work project started
  Project:  <Name>
  Folder:   1_Projects/<Name>/
  Color:    <color>
  Open Qs:  <count>

Run these to label this session:
  /rename proj: <Name>
  /color <color>

Next:
  clarify the open questions, then /technical-plan
```

Stop. Plans and the TRD come next, in this same session. This session is the planner, so keep it running.

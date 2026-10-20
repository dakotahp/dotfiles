---
name: start-work-project
description: Starts a work project from a Linear project. Creates the project's folder in the Work vault, links it to Linear, picks a session color, writes a brief with open questions, and names this session as the project's planner. Use at the start of a Linear project, before /technical-plan and /technical-requirements-document, or when the user runs /start-work-project.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, mcp__linear-server__get_project, mcp__linear-server__list_issues, mcp__linear-server__get_issue, mcp__linear-server__list_documents, mcp__linear-server__get_document, mcp__linear-server__list_milestones, mcp__linear-server__list_projects, mcp__obsidian-vault
---

Start the work project for the Linear project in $ARGUMENTS (a URL, ID, or name).

The vault project folder is my private home for this project. Linear stays the team-facing record: published plans, TRDs, and tickets. The vault holds what only serves me: plan drafts before I publish them, session names, the project color, and later a record of my contribution. Never write vault paths, session names, or the color into Linear.

## Where things live

- Vault: the Work vault. Projects are `1_Projects/<Name>/`. Archived projects are `4_Archive/1_Projects/<Name>/`.

## Step 1: Read the Linear project

Fetch the project, its documents, milestones, and tickets. If $ARGUMENTS is a name with more than one match, ask which one.

## Step 2: Check for an existing folder

Find the project note: `find_notes` in the Work vault with `frontmatter_key: linear-project-id` and the Linear project ID as the value. If it finds one, stop and suggest `/continue-project "<Name>"`.

The folder name is the Linear project name, minus characters a file name cannot hold. If `1_Projects/<Name>/<Name>.md` exists without `linear-project-id`, ask before adding the Linear fields to it with `update_frontmatter`, which keeps its body.

## Step 3: Pick a color

Palette, in tie-break order: `purple`, `blue`, `green`, `orange`, `pink`, `cyan`, `yellow`, `red`.

`find_notes` in the Work vault with `frontmatter_key: color` returns every note with a color. Count only main notes (`<Name>/<Name>.md`): 2 points each under `1_Projects/`, 1 point each under `4_Archive/1_Projects/`. Pick the color with the lowest score.

## Step 4: Write the main file

Create `1_Projects/<Name>/<Name>.md` in the Work vault with `create_note`:

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

## Decision log

My calls in the planner session, kept for `/end-task` and `/end-work-project`. Vault only, never Linear.

## Sessions

- YYYY-MM-DD · planning · proj: <Name>
```

Write `tickets:` as an inline list, for example `tickets: [APP-101, APP-102]`. Other skills add to it.

Ground the brief in the Linear text and, when the repo is at hand, the code. An open question is something I must answer or ask someone. Do not list questions the code answers; answer them.

## The decision log

This session is the planner for the life of the project. Ticket sessions see only their ticket, so the planner is the only record of how the work took shape. From this step on, add a line to `## Decision log` with `edit_section` in `append` mode each time I:

- ask to dig into a problem instead of shipping around it
- add scope, cut scope, or split work into new tickets
- make a call that changes the plan, or set a rule other tickets follow
- catch an error in the plan, a ticket, or a lane's work
- get a stakeholder's approval, or push back on a stakeholder

Answers the TRD or the code already gave do not count. Record facts, not praise:

```markdown
- YYYY-MM-DD · <ticket IDs, or "no ticket"> · Raised by <the planner, the lane for <ID>, me, or a person>. <What I decided, and why.> <Approved by <person>, if anyone.>
```

The log, and any framing of my contribution, stays in the vault. A Linear ticket, comment, or document states the work, never who thought of it.

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

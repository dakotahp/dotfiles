---
name: end-work-project
description: Closes out a finished work project. Writes a project summary into the project's vault main file from its task notes and decision log, suggests resume candidates against my Resume Items note, then archives the project folder. Use when every ticket in a work project is done or deliberately left behind, when the planner reports no open tickets, or when the user runs /end-work-project.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, ListAgents, Skill, mcp__linear-server__get_project, mcp__linear-server__list_issues, mcp__linear-server__get_issue, mcp__linear-server__list_comments, mcp__linear-server__get_status_updates, mcp__obsidian-vault
---

Close out the work project in $ARGUMENTS (a name or Linear project ID), or the project this session plans.

Act as a **supportive manager writing my end-of-project review**. Collect the facts that show ownership, initiative, risks caught, and judgment, while the work is still fresh. Do not rate my level or write a career story. A separate skill does that later, from these summaries. Every claim needs evidence, and nothing gets inflated.

The summary exists so that I mine one note per project later, not every task note. Write it to stand alone.

## Where things live

- Vault: the Work vault. The project folder is `1_Projects/<Name>/`, with the main file `<Name>.md`, task notes in `Tasks/`, and drafts in `Plans/`.
- Resume note: `2_Areas/Resume Items/Resume Items.md` in the Work vault. If it is not there, find it with `search_notes` for "Resume Items". It is my note, and its `## Resume items` section is my live resume. Never edit that section.
- Nothing from this skill goes into Linear.

## Step 1: Find the project

In this order:
1. $ARGUMENTS: `find_notes` in the Work vault with `frontmatter_key: linear-project-id` and the ID, or the main file `1_Projects/<Name>/<Name>.md`.
2. This session's name, the first line of `ListAgents`: `find_notes` with `frontmatter_key: planner-session` and that name. Skip this when `ListAgents` is not available.
3. The session-start context.

If none matches, ask.

If the folder is under `4_Archive/` and its main file has a `## Project summary`, stop and say the project is closed. Without a summary, an earlier run archived it but did not finish. Continue, and skip Step 7.

## Step 2: Check the tickets

Fetch the project's tickets and their states from Linear. Compare them with `tickets:` in the main file:

- A ticket in Linear but not in `tickets:` counts as a project ticket. Name it in the report.
- An ID in `tickets:` that Linear does not list in the project: fetch it with `get_issue`. A moved ticket comes back under a new ID, team, or project. List it under Follow-ups with its new ID and owner, for example "IQD-4789 (was APP-5049), IQ Data Team". It is not a ticket left behind.

Sort the project tickets into done, canceled, and open. If a ticket is open, list the open tickets and ask whether to leave them behind as follow-ups or stop.

A done ticket with no note in `Tasks/` is not a blocker. Its evidence is the Linear ticket, its comments, and its PR, if it has one. The summary says it has no task note.

## Step 3: Gather the facts

- The main file: the brief, Session Context, `## Decision log`, and `## Sessions`.
- Older projects have no decision log. Their calls are in the open questions marked "(my call, YYYY-MM-DD)" and in Brief lines such as "decided YYYY-MM-DD with product". Cite those as "Open questions, <item>" or "Brief, <item>".
- Every task note in `Tasks/`, with `read_notes` in batches of 20: highlights and their lenses, resume bullets, loose ends.
- The drafts in `Plans/`: Key Decisions and Out of Scope, where they exist.
- The Linear project's status updates.
- If this session is the planner, its own history. Add any call of mine that the log is missing first, in the format `/start-work-project` gives. Use `edit_section` in `append` mode. If the main file has no `## Decision log`, first insert the heading above `## Sessions` with `edit_note`.

**Credit me only for what I asked for, decided, approved, or caught.** Task notes sometimes say "I" for work an agent did on its own, such as a lane session finding a spec gap. That work is the pipeline's, not mine, unless I directed it.

## Step 4: Write the project summary

Read the main file with `read_note`. If it has a `## Project summary` already, show me the difference and ask before replacing it. Otherwise, insert the summary with `edit_note` and the version `read_note` returned. Find `## Brief` and replace it with the summary followed by `## Brief`. Without a `## Brief`, insert it above the first `## ` heading.

```markdown
## Project summary

**Closed:** YYYY-MM-DD. <One or two sentences: the outcome, who it reaches today, and who took the handoff.> <N> tickets done<; M left behind: IDs>.

**What shipped**

- <an outcome as a customer would describe it, not a ticket title> (<ticket IDs>)

**Highlights**

- **<short label>** (<lens>): <what I did and why it mattered, in at most two sentences>. Evidence: [[Tasks/<ID>]], or Decision log YYYY-MM-DD.

**Resume bullets**

- <"Did X, which led to Y", or "None for this project.">

**Follow-ups left behind**

- <open tickets, moved tickets with their new IDs, backlog items in other projects, and tooling lessons, or omit the heading>
```

Rules for highlights:
- Highlights are project level. When several tickets show the same thing, merge them into one highlight that links each task note.
- Keep the strongest, at most eight.
- A decision log line with no task note behind it can be a highlight. Planning calls are often the strongest ones.
- No evidence, no highlight. Delivering the project as planned is the baseline.
- Use a number only when a task note, the log, or Linear states it.
- Tag each highlight with the one lens it shows best. Keep the task note's lens, or assign one when the note has none:
  - `initiative`: I did something nobody asked for.
  - `ownership`: I carried the work past the edge of the ticket, such as QA, docs, or follow-through.
  - `risk`: I caught or prevented a failure before it reached customers.
  - `detail`: I found a subtle error that others missed.
  - `scope`: I added, cut, or protected scope on purpose.
  - `influence`: I set a rule or swayed a decision that others followed.
  - `cross-team`: I worked across a team boundary.

Rules for resume bullets:
- At most four, each one defensible from the highlights. Fewer defensible bullets beat more inflated ones. Zero is a valid result.
- State the real reach. If a beta flag, a feature switch, or a slow rollout limits who gets the result, the bullet says so, or it claims only what did happen.

## Step 5: Suggest resume candidates

Read the resume note's `## Resume items`, `## Candidate items (not yet on resume)`, and `## Retired items`. For each project resume bullet, pick one:

- **New candidate:** nothing in the note covers it.
- **Adds evidence to <item>:** an item or candidate already covers this ground, and the project is a concrete example or a sharper result. Quote the item.
- **Skip:** it is covered already, it was retired for a reason that still applies, or it is routine.

Show the list with a one-line reason for each. Ask with `AskUserQuestion`, `multiSelect: true`, which ones to write. Write only those, with `edit_section` in `append` mode on the candidate items heading. If the heading has changed, retry with the heading path the error lists.

Follow the note's own rules for what it holds:
- Each entry is a bold lead sentence, the detail, then `Source: [[<Name>]]`.
- An "adds evidence" entry names the item it supports, and says whether it should replace that item or sit under it as an example.
- If the result is not proven yet, or reaches only a few customers, mark the entry `NOT YET RESUME-READY` with a "promote when ..." condition.

If you wrote anything, set the resume note's `last-touched` to today with `update_frontmatter`.

## Step 6: Close the main file

- Set `status: done` and `last-touched` to today with `update_frontmatter`.
- In `## Session Context`, read the section with `get_section`. Replace the `**Status:**` line with `**Status:** Done YYYY-MM-DD. See Project summary.`, and keep the rest. Use `edit_section` in `replace` mode with the version `get_section` returned.

## Step 7: Archive

Run `/archive --folder "<Name>"` with the Skill tool. It asks me to confirm, then moves every note to `4_Archive/1_Projects/<Name>/` and updates links, including the `[[<Name>]]` source links in the resume note. If I decline, leave the folder in place.

## Step 8: Report

```
Project closed
  Project:     <Name>
  Tickets:     <done> done, <left> left behind, <moved> moved to other teams
  Highlights:  <count>
  Resume:      <new> new, <evidence> adds evidence, <not written> not written
  Archived:    <4_Archive/1_Projects/<Name>/, or "not archived">
```

If this session is the planner, say that its work is done and I can close it.

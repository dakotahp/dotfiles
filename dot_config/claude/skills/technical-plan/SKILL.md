---
name: technical-plan
description: Writes a concise technical plan from a project brief, Linear project or issue, or a rough description. Produces a human-facing overview of the approach, the decisions that matter, blast radius, risks, and sequencing. Use when someone needs to understand how a piece of work will be built before it is broken into tickets, or asks for a technical plan, a technical approach, or a design overview. Follow it with /technical-requirements-document in the same session when detailed specs are needed.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch, AskUserQuestion, Task, mcp__linear-server__get_project, mcp__linear-server__get_issue, mcp__linear-server__list_issues, mcp__linear-server__get_document
---

Write a technical plan for the work described in $ARGUMENTS.

Act as a **staff engineer briefing colleagues**. The reader is a human who needs to understand the shape of the work and why it is shaped that way. They are not implementing from this document, so it does not need to be exhaustive; it needs to be correct, grounded, and short enough that they will actually read it.

Best run in a `plan` session, where the model and effort are already pinned for this kind of work.

---

## Step 0: Get the input and ground it in the code

If $ARGUMENTS is a Linear project or issue identifier or URL, fetch it. If it is a file path, read it. If it is a URL, fetch it. If it is prose, use it directly.

Then read the actual code. A technical plan that has not been checked against the repository is a guess, and the most expensive kind of error here is an approach built on a seam that does not exist. Trace each significant noun in the request to what it really maps to in this codebase and note the path. Watch for similarly-named decoys.

Ask a question only if you cannot proceed without it. If you can make a reasonable assumption, make it and record it in Risks and Unknowns rather than blocking on a question.

---

## Step 1: Write the plan

Save to `docs/plans/YYYY-MM-DD-<slugified-name>-technical-plan.md`.

Respect the budget on each section. The budgets are the point of this skill: they are what keeps the document readable, and a section that runs long is almost always padding rather than substance.

```markdown
# Technical Plan: <Name>

**Date:** YYYY-MM-DD
**Status:** Draft
**Source:** <Linear project/issue, doc link, or "conversation">

---

## Summary

<3 to 4 sentences. What we are building and why, in terms a teammate outside this codebase would follow. No implementation detail.>

## Current State

<3 to 5 bullets, or skip the section if the work is greenfield. Only what is needed to understand why the approach is shaped the way it is. Cite paths.>

## Approach

<The core of the document. 2 to 4 short paragraphs, or a tight bulleted structure. How the pieces fit together and where the work lands. Name the components and boundaries involved. Enough that a reader can picture the change without reading code.>

## Key Decisions

<The highest-value section, because this is the part that cannot be recovered by reading the code later. One row per decision that a reasonable engineer might have made differently. If there are no real decisions, say so and delete the table.>

| Decision | Chose | Instead of | Why |
|---|---|---|---|
| <what was decided> | <the option taken> | <the plausible alternative> | <the reason, in one line> |

## Affected Areas

<Bullets at the level of subsystem or module, with paths. Blast radius, not a file manifest. Flag anything with consumers outside this codebase.>

## Risks and Unknowns

<One row each. Include assumptions you could not verify against the code, and say what would resolve each. "None" is a valid answer only if you actually looked.>

| Risk or unknown | Impact if wrong | How to resolve |
|---|---|---|

## Sequencing

<Numbered phases. What has to happen before what, and what can run in parallel. Phases, not tickets: ticket breakdown belongs in the TRD.>

## Out of Scope

<Bullets. What this work deliberately does not do, including the adjacent things a reader would otherwise assume are included.>
```

---

## What this document does not contain

Leave these out. Some belong in the TRD, and the rest belong nowhere.

- **Schemas, field lists, endpoint signatures, pseudocode, and interface definitions.** These are the TRD's job. Including them here is what turns a readable plan into an unreadable one.
- **Per-ticket breakdown and acceptance criteria.** Also the TRD's job.
- **The request restated back.** The reader has it.
- **An alternatives-considered essay.** The Key Decisions table already carries the alternative in one line, which is all a reader needs.
- **A closing summary or conclusion.** The document opens with the summary; repeating it at the end adds length and no information.
- **Hedged filler.** "We should consider carefully evaluating" is not a decision. Make the call, or list it as an open question with an owner.

---

## Step 2: Print a summary

```
Technical plan written
  Work:      <name>
  Saved to:  <file path>
  Decisions: <count>
  Risks:     <count>

Next steps:
  /technical-requirements-document   detailed specs and ticket breakdown, same session
  plan-falsifier <path>             verify the plan's assumptions against the code
  plan-rederiver                    independent plan from the brief, to diff for blind spots
```

Offer `plan-falsifier` and `plan-rederiver` explicitly rather than assuming the user knows about them. The plan stage is where they pay off most, since an error here propagates into every ticket downstream. Dispatch both in one message so they run concurrently, and pass `plan-rederiver` only the original brief, never the plan.

---

## Writing principles

**Brevity through omission, not compression.** Cut whole sections that do not earn their place. Do not keep every section and write it in fragments, abbreviations, or arrow chains; that is harder to read, not shorter to read.

**Ground every claim about the existing system.** Cite a path. An ungrounded assertion in a plan becomes a false premise in a ticket, and by then it costs an implementation session to discover.

**A decision without its alternative is not a decision.** If the Instead-of column would be empty, that row is a description of the work, not a decision. Move it to Approach.

**State unknowns as unknowns.** A plan that reads as more confident than the evidence supports is worth less than one that flags its gaps, because the gaps surface later either way.
